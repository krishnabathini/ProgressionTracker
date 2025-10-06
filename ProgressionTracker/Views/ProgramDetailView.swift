import SwiftUI
import SwiftData

/// Detail view for a workout program showing workout days and rotation tracking
struct ProgramDetailView: View {
    @Bindable var program: WorkoutProgram
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddDayAlert = false
    @State private var newDayName = ""
    @State private var dayToDelete: WorkoutDay?
    @State private var showingDeleteAlert = false
    @State private var showingSkipAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Top Section: Next Workout (only show if program has days)
                    if !program.days.isEmpty {
                        nextWorkoutSection
                    }
                    
                    // Main Section: All Workout Days
                    if program.days.isEmpty {
                        emptyStateView
                    } else {
                        workoutDaysSection
                    }
                }
                .padding()
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
            .navigationTitle(program.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddDayAlert = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
        }
        .alert("Add Workout Day", isPresented: $showingAddDayAlert) {
            TextField("Day Name", text: $newDayName)
            Button("Add") {
                addWorkoutDay()
            }
            .disabled(newDayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {
                newDayName = ""
            }
        } message: {
            Text("Enter a name for your workout day")
        }
        .alert("Delete Workout Day", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteWorkoutDay()
            }
            Button("Cancel", role: .cancel) {
                dayToDelete = nil
            }
        } message: {
            if let day = dayToDelete {
                Text("Are you sure you want to delete '\(day.name)'? This action cannot be undone.")
            }
        }
        .alert("Skip Workout Day", isPresented: $showingSkipAlert) {
            Button("Skip", role: .destructive) {
                skipWorkoutDay()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let _ = program.nextWorkoutDay {
                Text("Move to next workout without logging sets?")
            }
        }
    }
    
    // MARK: - Next Workout Section
    
    /// Displays the next workout day with Start/Skip buttons
    private var nextWorkoutSection: some View {
        VStack(spacing: 16) {
            if let nextDay = program.nextWorkoutDay {
                VStack(spacing: 12) {
                    // "UP NEXT" label
                    Text("UP NEXT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    // Day name
                    Text(nextDay.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Start Workout button
                        NavigationLink(destination: WorkoutDayDetailView(workoutDay: nextDay)) {
                            Text("Start Workout")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        // Skip button
                        Button(action: {
                            showingSkipAlert = true
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()
                .background(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Workout Days Section
    
    /// Displays the list of all workout days
    private var workoutDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Workout Days")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(sortedWorkoutDays) { day in
                    NavigationLink(destination: WorkoutDayDetailView(workoutDay: day)) {
                        WorkoutDayRowView(
                            day: day,
                            isNext: day == program.nextWorkoutDay,
                            isLast: day.orderIndex == program.lastCompletedDayIndex
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Empty State View
    
    /// Displays when no workout days exist
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Workout Days")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Add your first workout day to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: {
                showingAddDayAlert = true
            }) {
                Text("Add Workout Day")
                    .font(.headline)
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
    
    // MARK: - Workout Day Row View
    
    /// Individual row view for displaying a workout day
    private struct WorkoutDayRowView: View {
        let day: WorkoutDay
        let isNext: Bool
        let isLast: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Day name
                        Text(day.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Badges
                        HStack(spacing: 6) {
                            if isNext {
                                Text("NEXT")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            
                            if isLast {
                                Text("LAST")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Number of exercises
                    Text(day.exercises.isEmpty ? "No exercises yet" : "\(day.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Right chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns workout days sorted by orderIndex
    private var sortedWorkoutDays: [WorkoutDay] {
        program.days.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // MARK: - Actions
    
    /// Adds a new workout day to the program
    private func addWorkoutDay() {
        let trimmedName = newDayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Calculate next orderIndex
        let nextOrderIndex = sortedWorkoutDays.count
        
        // Create new workout day
        let newDay = WorkoutDay(
            program: program,
            name: trimmedName,
            orderIndex: nextOrderIndex
        )
        
        // Add to program and save
        program.days.append(newDay)
        modelContext.insert(newDay)
        
        do {
            try modelContext.save()
            print("Added workout day '\(trimmedName)' to program '\(program.name)'")
        } catch {
            print("Error saving workout day: \(error)")
        }
        
        newDayName = ""
    }
    
    /// Skips the current workout day
    private func skipWorkoutDay() {
        program.skipToNextDay()
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        do {
            try modelContext.save()
            print("Skipped to next workout day")
        } catch {
            print("Error saving skip action: \(error)")
        }
    }
    
    /// Confirms deletion of a workout day
    /// - Parameter indexSet: The indices of days to delete
    private func confirmDelete(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        dayToDelete = sortedWorkoutDays[index]
        showingDeleteAlert = true
    }
    
    /// Deletes the selected workout day
    private func deleteWorkoutDay() {
        guard let day = dayToDelete else { return }
        
        // Remove from program's days array
        program.days.removeAll { $0.id == day.id }
        
        // Delete from database
        modelContext.delete(day)
        
        // Update orderIndexes for remaining days
        updateOrderIndexes()
        
        do {
            try modelContext.save()
            print("Deleted workout day '\(day.name)'")
        } catch {
            print("Error deleting workout day: \(error)")
        }
        
        dayToDelete = nil
    }
    
    /// Updates orderIndexes for all remaining workout days
    private func updateOrderIndexes() {
        for (index, day) in sortedWorkoutDays.enumerated() {
            day.orderIndex = index
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutProgram.self, WorkoutDay.self, configurations: config)
    
    let program = WorkoutProgram(name: "Push Pull Legs")
    let pushDay = WorkoutDay(program: program, name: "Push Day", orderIndex: 0)
    let pullDay = WorkoutDay(program: program, name: "Pull Day", orderIndex: 1)
    let legDay = WorkoutDay(program: program, name: "Leg Day", orderIndex: 2)
    
    program.days = [pushDay, pullDay, legDay]
    
    return ProgramDetailView(program: program)
        .modelContainer(container)
}
