import SwiftUI
import SwiftData

/// Main home screen displaying all workout programs with empty state handling
struct ProgramListView: View {
    @Query(sort: \WorkoutProgram.createdDate, order: .reverse) private var programs: [WorkoutProgram]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingTemplates = false
    @State private var programToDelete: WorkoutProgram?
    @State private var showingDeleteAlert = false
    
    /// Calculates the overall current workout streak across all programs
    private var currentStreak: Int {
        // Aggregate streaks from all programs and return the highest
        // Alternatively, calculate based on all sessions across all programs
        return programs.map { $0.currentStreak }.max() ?? 0
    }
    
    /// Returns a warning message if the user needs to workout today to maintain their streak
    private var streakWarningMessage: String? {
        return programs.first?.streakWarningMessage
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if programs.isEmpty {
                    // Empty state when no programs exist
                    emptyStateView
                } else {
                    // List of existing programs
                    programListView
                }
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
            .navigationTitle("My Programs")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingTemplates = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplates) {
            ProgramTemplateSelectionView()
        }
        .alert("Delete Program", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteProgram()
            }
            Button("Cancel", role: .cancel) {
                programToDelete = nil
            }
        } message: {
            if let program = programToDelete {
                Text("Are you sure you want to delete '\(program.name)'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Empty State View
    
    /// Displays when no workout programs exist
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Large SF Symbol icon
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                // Main empty state title
                Text("No Programs Yet")
                    .font(.system(.title2, design: .default, weight: .semibold))
                    .foregroundColor(.white)
                
                // Subtitle explaining what to do
                Text("Get started by choosing a workout program")
                    .font(.system(.body, design: .default, weight: .regular))
                    .foregroundColor(Color(white: 0.6))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Call-to-action button
            Button(action: {
                showingTemplates = true
            }) {
                Text("Choose Program")
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Program List View
    
    /// Displays the list of existing workout programs
    private var programListView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(programs) { program in
                    NavigationLink(destination: ProgramDetailView(program: program)) {
                        ProgramRowView(program: program)
                    }
                    .listRowBackground(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: confirmDelete)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // Streak indicator
            streakIndicatorView
        }
    }
    
    // MARK: - Streak Indicator View
    
    /// Displays the current workout streak with a fire emoji
    private var streakIndicatorView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("\(currentStreak)")
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Day Streak")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(Color(white: 0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                .cornerRadius(12)
                
                // Streak warning message
                if let warningMessage = streakWarningMessage {
                    Text(warningMessage)
                        .font(.system(.caption, design: .default, weight: .medium))
                        .foregroundColor(.yellow)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
    }
    
    // MARK: - Program Row View
    
    /// Individual row view for displaying a workout program
    private struct ProgramRowView: View {
        let program: WorkoutProgram
        
        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // Program name
                    Text(program.name)
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    // Number of workout days
                    Text("\(program.days.count) days")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(Color(white: 0.6))
                    
                    // Next workout day or start message
                    if let nextDay = program.nextWorkoutDay {
                        Text("Next: \(nextDay.name)")
                            .font(.system(.subheadline, design: .default, weight: .medium))
                            .foregroundColor(.green)
                    } else if program.days.isEmpty {
                        Text("Add workout days")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    } else {
                        Text("Start your first workout")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Right chevron
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
//                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Delete Functionality
    
    /// Confirms deletion of a program
    /// - Parameter indexSet: The indices of programs to delete
    private func confirmDelete(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        programToDelete = programs[index]
        showingDeleteAlert = true
    }
    
    /// Deletes the selected program from the database
    private func deleteProgram() {
        guard let program = programToDelete else { return }
        
        // Delete the program (SwiftData will handle cascading deletes)
        modelContext.delete(program)
        
        do {
            try modelContext.save()
            print("Deleted program '\(program.name)'")
        } catch {
            print("Error deleting program: \(error)")
        }
        
        programToDelete = nil
    }
}

#Preview {
    ProgramListView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutDay.self])
}

#Preview("Empty State") {
    ProgramListView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutDay.self])
}
