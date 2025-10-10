import SwiftUI
import SwiftData

/// Detail view for a workout day showing exercises and allowing exercise management
struct WorkoutDayDetailView: View {
    @Bindable var workoutDay: WorkoutDay
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseLibrary: [ExerciseLibraryItem]
    
    @State private var showingExerciseSearch = false
    @State private var exerciseToDelete: Exercise?
    @State private var showingDeleteAlert = false
    @State private var showingSetTarget = false
    @State private var selectedLibraryItem: ExerciseLibraryItem?
    @State private var customExerciseName = ""
    @State private var targetSets = 3
    @State private var targetReps = 8
    
    var body: some View {
        NavigationStack {
            Group {
                if workoutDay.exercises.isEmpty {
                    emptyStateView
                } else {
                    exerciseListView
                }
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
            .navigationTitle(workoutDay.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingExerciseSearch = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingExerciseSearch) {
            ExerciseSearchView(
                exerciseLibrary: exerciseLibrary,
                onSelectLibraryItem: { item in
                    selectedLibraryItem = item
                    customExerciseName = ""
                    showingSetTarget = true
                    showingExerciseSearch = false
                },
                onCreateCustom: { name in
                    selectedLibraryItem = nil
                    customExerciseName = name
                    showingSetTarget = true
                    showingExerciseSearch = false
                }
            )
        }
        .sheet(isPresented: $showingSetTarget) {
            SetTargetView(
                exerciseName: customExerciseName.isEmpty ? selectedLibraryItem?.name ?? "" : customExerciseName,
                targetSets: $targetSets,
                targetReps: $targetReps,
                onSave: {
                    addExercise()
                },
                onCancel: {
                    resetTargetForm()
                }
            )
        }
        .alert("Delete Exercise", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteExercise()
            }
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
        } message: {
            if let exercise = exerciseToDelete {
                Text("Are you sure you want to delete '\(exercise.name)'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Empty State View
    
    /// Displays when no exercises exist in the workout day
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Exercises Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Add exercises to start tracking your workouts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: {
                showingExerciseSearch = true
            }) {
                Text("Add Exercise")
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
    
    // MARK: - Exercise List View
    
    /// Displays the list of exercises in the workout day
    private var exerciseListView: some View {
        List {
            ForEach(workoutDay.exercises) { exercise in
                NavigationLink {
                    ExerciseTrackingView(exercise: exercise)
                } label: {
                    ExerciseRowView(exercise: exercise, badgeColor: circleColor(for: exercise))
                }
                .listRowBackground(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: confirmDelete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Exercise Row View
    
    /// Individual row view for displaying an exercise with progress badge
    private struct ExerciseRowView: View {
        let exercise: Exercise
        let badgeColor: Color
        
        var body: some View {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // Exercise name
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // Target sets and reps
                    Text("Target: \(exercise.targetSets) sets × \(exercise.targetReps) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress badge
                ProgressBadgeView(exercise: exercise, color: badgeColor)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Progress Badge View
    
    /// Shows progress status for an exercise based on workout history
    private struct ProgressBadgeView: View {
        let exercise: Exercise
        let color: Color
        
        var body: some View {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
    }
    
    // MARK: - Actions
    
    /// Determines the exercise type based on the exercise name
    /// - Parameter exerciseName: The name of the exercise
    /// - Returns: The appropriate ExerciseType
    private func determineExerciseType(for exerciseName: String) -> ExerciseType {
        let lowercaseName = exerciseName.lowercased()
        
        // Check for lower body exercise keywords
        if lowercaseName.contains("squat") || 
           lowercaseName.contains("leg") || 
           lowercaseName.contains("deadlift") || 
           lowercaseName.contains("lunge") || 
           lowercaseName.contains("calf") {
            return .lowerBody
        }
        
        // Default to upper body for most exercises
        return .upperBody
    }
    
    /// Adds a new exercise to the workout day
    private func addExercise() {
        let exercise: Exercise
        
        if let libraryItem = selectedLibraryItem {
            // Create exercise from library item - use library item's type
            exercise = Exercise(
                day: workoutDay,
                name: libraryItem.name,
                targetSets: targetSets,
                targetReps: targetReps,
                exerciseType: libraryItem.type,
                libraryItem: libraryItem
            )
        } else {
            // Create custom exercise - automatically determine type
            let determinedType = determineExerciseType(for: customExerciseName)
            exercise = Exercise(
                day: workoutDay,
                name: customExerciseName,
                targetSets: targetSets,
                targetReps: targetReps,
                exerciseType: determinedType,
                libraryItem: nil
            )
        }
        
        // Add to workout day and save
        workoutDay.exercises.append(exercise)
        modelContext.insert(exercise)
        
        do {
            try modelContext.save()
            print("Added exercise '\(exercise.name)' to workout day '\(workoutDay.name)'")
        } catch {
            print("Error saving exercise: \(error)")
        }
        
        resetTargetForm()
    }
    
    /// Resets the target form to default values
    private func resetTargetForm() {
        selectedLibraryItem = nil
        customExerciseName = ""
        targetSets = 3
        targetReps = 8
    }
    
    /// Confirms deletion of an exercise
    /// - Parameter indexSet: The indices of exercises to delete
    private func confirmDelete(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        exerciseToDelete = workoutDay.exercises[index]
        showingDeleteAlert = true
    }
    
    /// Deletes the selected exercise
    private func deleteExercise() {
        guard let exercise = exerciseToDelete else { return }
        
        // Remove from workout day's exercises array
        workoutDay.exercises.removeAll { $0.id == exercise.id }
        
        // Delete from database
        modelContext.delete(exercise)
        
        do {
            try modelContext.save()
            print("Deleted exercise '\(exercise.name)'")
        } catch {
            print("Error deleting exercise: \(error)")
        }
        
        exerciseToDelete = nil
    }
    
    private func getCompletionStatus(for exercise: Exercise) -> (completed: Int, target: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get all sessions for this exercise today
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            return (0, exercise.targetSets)
        }
        
        // Filter for today's sessions with this exercise
        let todaySessions = allSessions.filter { session in
            Calendar.current.isDate(session.date, inSameDayAs: today)
        }
        
        // Count completed sets for this exercise
        var completedSets = 0
        for session in todaySessions {
            completedSets += session.sets.filter { $0.exercise?.persistentModelID == exercise.persistentModelID && $0.isCompleted }.count
        }
        
        return (completedSets, exercise.targetSets)
    }
    
    private func circleColor(for exercise: Exercise) -> Color {
        let status = getCompletionStatus(for: exercise)
        
        if status.completed == 0 {
            return Color(white: 0.4) // Gray - not started
        } else if status.completed >= status.target {
            return Color.green // Green - target met
        } else {
            return Color.yellow // Yellow - in progress
        }
    }
}

// MARK: - Exercise Search View

/// Sheet view for searching and selecting exercises from the library
struct ExerciseSearchView: View {
    let exerciseLibrary: [ExerciseLibraryItem]
    let onSelectLibraryItem: (ExerciseLibraryItem) -> Void
    let onCreateCustom: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredExercises: [ExerciseLibraryItem] {
        if searchText.isEmpty {
            return exerciseLibrary
        } else {
            return ExerciseLibraryService.searchExercises(query: searchText, in: exerciseLibrary)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                List {
                    // Create custom option (only show if search is not empty)
                    if !searchText.isEmpty {
                        Button(action: {
                            onCreateCustom(searchText)
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                Text("Create: \(searchText)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.blue.opacity(0.1))
                    }
                    
                    // Grouped exercises by category
                    ForEach(ExerciseCategory.allCases) { category in
                        let categoryExercises = filteredExercises.filter { $0.category == category }
                        
                        if !categoryExercises.isEmpty {
                            Section(category.displayName) {
                                ForEach(categoryExercises) { exercise in
                                    Button(action: {
                                        onSelectLibraryItem(exercise)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(exercise.name)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                
                                                Text(exercise.category.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Search Bar

/// Custom search bar component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search exercises...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Set Target View

/// Sheet view for setting exercise targets
struct SetTargetView: View {
    let exerciseName: String
    @Binding var targetSets: Int
    @Binding var targetReps: Int
    
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Exercise name
                Text(exerciseName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(spacing: 20) {
                    // Target sets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Sets")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Stepper(value: $targetSets, in: 1...10) {
                            Text("\(targetSets) sets")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Target reps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Reps")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Stepper(value: $targetReps, in: 1...50) {
                            Text("\(targetReps) reps")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
            .navigationTitle("Set Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Exercise") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutProgram.self, WorkoutDay.self, Exercise.self, ExerciseLibraryItem.self, configurations: config)
    
    let program = WorkoutProgram(name: "Push Pull Legs")
    let workoutDay = WorkoutDay(program: program, name: "Push Day", orderIndex: 0)
    
    return WorkoutDayDetailView(workoutDay: workoutDay)
        .modelContainer(container)
}
