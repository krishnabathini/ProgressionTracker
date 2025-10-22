import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workoutDates: Set<Date> = []
    @State private var showWorkoutHistory = false
    @State private var showGitHubAuth = false
    @State private var showGitHubSettings = false
    @ObservedObject private var authService = GitHubAuthService.shared
    @ObservedObject private var gitHubSettings = GitHubSettingsService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User info section
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)
                        
                        Text("Workout Stats")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Stats cards
                    HStack(spacing: 12) {
                        Button {
                            showWorkoutHistory = true
                        } label: {
                            StatCard(title: "Total Workouts", value: "\(workoutDates.count)", color: .green)
                        }
                        .buttonStyle(.plain)
                        
                        StatCard(title: "This Week", value: "\(workoutsThisWeek())", color: .blue)
                    }
                    .padding(.horizontal, 20)
                    
                    // GitHub Integration Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GitHub Integration")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        Button {
                            showGitHubAuth = true
                        } label: {
                            HStack {
                                Image(systemName: authService.isAuthenticated ? "link.circle.fill" : "link.circle")
                                    .font(.system(size: 24))
                                    .foregroundStyle(authService.isAuthenticated ? .green : .blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(authService.isAuthenticated ? "Connected to GitHub" : "Connect to GitHub")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    
                                    if authService.isAuthenticated, let user = authService.currentUser {
                                        Text("@\(user.login)")
                                            .font(.caption)
                                            .foregroundStyle(Color(white: 0.6))
                                    } else {
                                        Text("Sync your workouts to GitHub")
                                            .font(.caption)
                                            .foregroundStyle(Color(white: 0.6))
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(white: 0.5))
                            }
                            .padding()
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        
                        // GitHub Settings (only show if connected)
                        if authService.isAuthenticated {
                            Button {
                                showGitHubSettings = true
                            } label: {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.gray)
                                    
                                    Text("GitHub Settings")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(white: 0.5))
                                }
                                .padding()
                                .background(Color(hex: "2C2C2E"))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Workout heatmap
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Activity")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        WorkoutHeatmap(workoutDates: workoutDates)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .background(Color(hex: "1C1C1E"))
            .navigationTitle("Profile")
        }
        .onAppear {
            loadWorkoutDates()
        }
        .sheet(isPresented: $showWorkoutHistory) {
            WorkoutHistoryView()
                .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: $showGitHubAuth) {
            GitHubAuthView()
        }
        .sheet(isPresented: $showGitHubSettings) {
            GitHubSettingsView()
        }
    }
    
    private func loadWorkoutDates() {
        let descriptor = FetchDescriptor<WorkoutSession>()
        guard let sessions = try? modelContext.fetch(descriptor) else { return }
        
        let calendar = Calendar.current
        workoutDates = Set(sessions.map { calendar.startOfDay(for: $0.date) })
    }
    
    private func workoutsThisWeek() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return workoutDates.filter { $0 >= weekAgo }.count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(Color(white: 0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(12)
    }
}

struct WorkoutHeatmap: View {
    let workoutDates: Set<Date>
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    
    // Generate all weeks of 2025
    private var heatmapData: [[Date?]] {
        var weeks: [[Date?]] = []
        
        // Start from the first day of 2025
        guard let startOfYear = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: 2025, month: 12, day: 31)) else {
            return []
        }
        
        // Find the start of the first week (go back to Sunday if needed)
        var currentDate = startOfYear
        let weekday = calendar.component(.weekday, from: startOfYear)
        if weekday != 1 { // If not Sunday
            currentDate = calendar.date(byAdding: .day, value: -(weekday - 1), to: startOfYear)!
        }
        
        // Generate weeks until we pass the end of year
        while currentDate <= endOfYear {
            var week: [Date?] = []
            
            // Generate 7 days for this week
            for _ in 0..<7 {
                let year = calendar.component(.year, from: currentDate)
                if year == 2025 {
                    week.append(currentDate)
                } else {
                    week.append(nil) // Dates outside 2025
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            weeks.append(week)
            
            // If we've gone past end of year, stop
            if let lastDate = week.last, let date = lastDate, date > endOfYear {
                break
            }
        }
        
        return weeks
    }
    
    // Calculate workout intensity (0-4 scale like GitHub)
    private func workoutIntensity(for date: Date?) -> Int {
        guard let date = date else { return 0 }
        
        let startOfDay = calendar.startOfDay(for: date)
        return workoutDates.contains(startOfDay) ? 3 : 0
    }
    
    // Color based on intensity
    private func colorForIntensity(_ intensity: Int) -> Color {
        switch intensity {
        case 0:
            return Color(hex: "2C2C2E") // Dark gray for no workout
        case 1:
            return Color(hex: "0E4429") // Light green
        case 2:
            return Color(hex: "006D32") // Medium green
        case 3:
            return Color(hex: "26A641") // Bright green
        case 4:
            return Color(hex: "39D353") // Brightest green
        default:
            return Color(hex: "2C2C2E")
        }
    }
    
    // Get month labels with their positions
    private var monthLabels: [(String, CGFloat)] {
        var labels: [(String, CGFloat)] = []
        var lastMonth: Int?
        
        for (weekIndex, week) in heatmapData.enumerated() {
            if let firstDate = week.first(where: { $0 != nil }),
               let date = firstDate {
                let month = calendar.component(.month, from: date)
                if month != lastMonth {
                    let xPosition = CGFloat(weekIndex) * (cellSize + cellSpacing)
                    let monthName = calendar.shortMonthSymbols[month - 1]
                    labels.append((monthName, xPosition))
                    lastMonth = month
                }
            }
        }
        
        return labels
    }
    
    // Day of week labels
    private var dayLabels: [String] {
        return ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // Month labels
                    ZStack(alignment: .topLeading) {
                        ForEach(monthLabels, id: \.0) { label in
                            Text(label.0)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(white: 0.6))
                                .offset(x: label.1, y: 0)
                        }
                    }
                    .frame(height: 16)
                    
                    // Heatmap grid
                    HStack(alignment: .top, spacing: 0) {
                        // Day labels on the left
                        VStack(alignment: .trailing, spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                Text(dayLabels[dayIndex])
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color(white: 0.5))
                                    .frame(width: 12, height: cellSize)
                            }
                        }
                        .padding(.trailing, 6)
                        
                        // Heatmap cells
                        HStack(spacing: cellSpacing) {
                            ForEach(0..<heatmapData.count, id: \.self) { weekIndex in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        let date = heatmapData[weekIndex][dayIndex]
                                        let intensity = workoutIntensity(for: date)
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(colorForIntensity(intensity))
                                            .frame(width: cellSize, height: cellSize)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .stroke(Color(white: 0.15), lineWidth: date == nil ? 0 : 0.5)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(hex: "2C2C2E"))
            .cornerRadius(12)
            
            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(white: 0.5))
                
                ForEach(0..<5, id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForIntensity(intensity))
                        .frame(width: 10, height: 10)
                }
                
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(white: 0.5))
            }
            .padding(.leading, 20)
            .padding(.top, 4)
        }
    }
}

