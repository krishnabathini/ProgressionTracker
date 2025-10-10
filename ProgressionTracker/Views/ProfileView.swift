import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workoutDates: Set<Date> = []
    
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
                        StatCard(title: "Total Workouts", value: "\(workoutDates.count)", color: .green)
                        StatCard(title: "This Week", value: "\(workoutsThisWeek())", color: .blue)
                    }
                    .padding(.horizontal, 20)
                    
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming Soon - GitHub-style workout heatmap")
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.5))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(12)
        }
    }
}

