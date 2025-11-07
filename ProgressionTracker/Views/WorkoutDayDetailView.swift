import SwiftUI
import SwiftData

struct WorkoutDayDetailView: View {
    @Bindable var workoutDay: WorkoutDay
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var gitHubAuth = GitHubAuthService.shared
    
    @State private var showingExerciseLibrary = false
    @State private var editingExercise: Exercise?
    @State private var showingEditSheet = false
    @State private var editTargetSets = 3
    @State private var editTargetReps = 10
    @State private var refreshTrigger = UUID()
    @State private var showingCompleteConfirmation = false
    @State private var showingGitHubError = false
    @State private var gitHubErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if workoutDay.exercises.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "dumbbell")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No exercises yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Add exercises to this workout day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1C1C1E"))
            } else {
                // Exercise list
                ZStack(alignment: .bottom) {
                    List {
                        ForEach(workoutDay.exercises.sorted(by: { $0.name < $1.name })) { exercise in
                            NavigationLink {
                                ExerciseTrackingView(exercise: exercise)
                            } label: {
                                ExerciseRowContent(
                                    day: workoutDay,
                                    exercise: exercise,
                                    circleColor: circleColor(for: exercise)
                                )
                            }
                            .listRowBackground(Color(hex: "2C2C2E"))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteExercise(exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingExercise = exercise
                                    editTargetSets = exercise.targetSets
                                    editTargetReps = exercise.targetReps
                                    showingEditSheet = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .id(refreshTrigger)  // Force view refresh when trigger changes
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: "1C1C1E"))
                    
                    // Complete Workout button
                    VStack {
                        Spacer()
                        
                        Button {
                            if allExercisesComplete() {
                                // Auto-complete without confirmation if all targets hit
                                completeWorkout()
                            } else {
                                // Show confirmation if targets not met
                                showingCompleteConfirmation = true
                            }
                        } label: {
                            Text(completeWorkoutButtonText())
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(allExercisesComplete() ? Color.green : Color.blue)
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(workoutDay.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingExerciseLibrary = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            ExerciseLibraryView(workoutDay: workoutDay)
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                VStack(spacing: 24) {
                    if let exercise = editingExercise {
                        VStack(spacing: 8) {
                            Text(exercise.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Update targets")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                    }
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("TARGET SETS")
                                .font(.caption)
                                .foregroundStyle(Color(white: 0.6))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button {
                                    if editTargetSets > 1 { editTargetSets -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white)
                                }
                                
                                Text("\(editTargetSets)")
                                    .font(.system(size: 36, weight: .bold))
                                    .frame(width: 60)
                                    .foregroundStyle(.white)
                                
                                Button {
                                    if editTargetSets < 10 { editTargetSets += 1 }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color(hex: "2C2C2E"))
                        .cornerRadius(12)
                        
                        HStack {
                            Text("TARGET REPS")
                                .font(.caption)
                                .foregroundStyle(Color(white: 0.6))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button {
                                    if editTargetReps > 1 { editTargetReps -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white)
                                }
                                
                                Text("\(editTargetReps)")
                                    .font(.system(size: 36, weight: .bold))
                                    .frame(width: 60)
                                    .foregroundStyle(.white)
                                
                                Button {
                                    if editTargetReps < 50 { editTargetReps += 1 }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color(hex: "2C2C2E"))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        saveExerciseTargets()
                    } label: {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(Color(hex: "1C1C1E"))
                .navigationTitle("Edit Targets")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            showingEditSheet = false
                            editingExercise = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Complete Workout", isPresented: $showingCompleteConfirmation) {
            Button("Complete Anyway") {
                completeWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You haven't completed all target sets. Complete workout anyway?")
        }
        .alert("GitHub Error", isPresented: $showingGitHubError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(gitHubErrorMessage)
        }
    }
    
    // MARK: - Workout Completion Functions
    
    private func completeWorkoutButtonText() -> String {
        if gitHubAuth.isAuthenticated {
            return allExercisesComplete() ? "commit workout ✓" : "commit workout"
        } else {
            return allExercisesComplete() ? "Workout Complete! ✓" : "Complete Workout"
        }
    }
    
    private func allExercisesComplete() -> Bool {
        guard !workoutDay.exercises.isEmpty else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            return false
        }
        
        let todaySessions = allSessions.filter { session in
            calendar.isDate(calendar.startOfDay(for: session.date), inSameDayAs: today)
        }
        
        // Check each exercise has completed target sets
        for exercise in workoutDay.exercises {
            var completedSets = 0
            for session in todaySessions {
                let exerciseSets = session.sets.filter { 
                    $0.exercise?.persistentModelID == exercise.persistentModelID && $0.isCompleted 
                }
                completedSets += exerciseSets.count
            }
            
            if completedSets < exercise.targetSets {
                return false
            }
        }
        
        return true
    }
    
    private func completeWorkout() {
        guard let program = workoutDay.program else { return }
        
        // Mark this day as completed in the program
        program.markDayCompleted(workoutDay)
        
        do {
            try modelContext.save()
            print("Workout completed! Next workout: \(program.nextWorkoutDay?.name ?? "None")")
            
            // Log to GitHub if authenticated
            if gitHubAuth.isAuthenticated {
                Task {
                    await logWorkoutToGitHub()
                }
            }
            
            // Provide haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Navigate back to program detail page
            dismiss()
            
        } catch {
            print("Error completing workout: \(error)")
        }
    }
    
    private func logWorkoutToGitHub() async {
        print("🔄 Attempting to log workout to GitHub...")
        print("   Repository: \(GitHubSettingsService.shared.repositoryName)")
        print("   Private: \(GitHubSettingsService.shared.isRepositoryPrivate)")
        
        // Fetch today's workout session to get all sets
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            print("   ❌ Failed to fetch sessions for GitHub logging")
            return
        }
        
        print("   📊 Found \(allSessions.count) total sessions")
        
        // Find today's session for this day
        guard let todaySession = allSessions.first(where: { session in
            calendar.isDate(calendar.startOfDay(for: session.date), inSameDayAs: today) &&
            session.day?.persistentModelID == workoutDay.persistentModelID
        }) else {
            print("   ❌ No session found for today")
            print("   Looking for day: \(workoutDay.name) (ID: \(workoutDay.persistentModelID))")
            print("   Today: \(today)")
            print("   Available sessions:")
            for session in allSessions.prefix(5) {
                print("     - \(session.date) | Day: \(session.day?.name ?? "nil") | Sets: \(session.sets.count)")
            }
            return
        }
        
        print("   ✅ Found today's session with \(todaySession.sets.count) sets")
        
        // Build workout data from the session
        var exercises: [ExerciseLogData] = []
        
        // Group sets by exercise
        let groupedSets = Dictionary(grouping: todaySession.sets) { set in
            set.exercise?.persistentModelID
        }
        
        print("   📊 Grouped sets by exercise:")
        for (exerciseID, sets) in groupedSets {
            if let exerciseID = exerciseID,
               let firstSet = sets.first,
               let exercise = firstSet.exercise {
                print("     - \(exercise.name): \(sets.count) sets")
            } else {
                print("     - Unknown exercise: \(sets.count) sets")
            }
        }
        
        for (exerciseID, sets) in groupedSets {
            guard let exerciseID = exerciseID,
                  let firstSet = sets.first,
                  let exercise = firstSet.exercise else {
                print("   ⚠️ Skipping set with missing exercise data")
                continue
            }
            
            let setData = sets.map { set in
                SetLogData(weight: set.weight, reps: set.reps, unit: "lbs")
            }
            
            exercises.append(ExerciseLogData(name: exercise.name, sets: setData))
        }
        
        print("   📊 Final exercises to log: \(exercises.count)")
        for exercise in exercises {
            print("     - \(exercise.name): \(exercise.sets.count) sets")
        }
        
        let workoutData = WorkoutLogData(
            programName: workoutDay.program?.name ?? "Workout",
            dayName: workoutDay.name,
            exercises: exercises
        )
        
        // Log to GitHub
        print("🔄 Attempting to log workout to GitHub...")
        print("   Repository: \(GitHubSettingsService.shared.repositoryName)")
        print("   Private: \(GitHubSettingsService.shared.isRepositoryPrivate)")
        print("   Exercises: \(exercises.count)")
        
        let result = await GitHubRepositoryService.shared.logWorkout(
            workoutData: workoutData,
            date: Date()
        )
        
        await MainActor.run {
            switch result {
            case .success:
                print("✅ Workout logged to GitHub successfully!")
            case .failure(let error):
                print("❌ Failed to log workout to GitHub: \(error)")
                gitHubErrorMessage = "Failed to log workout to GitHub: \(error.localizedDescription)"
                showingGitHubError = true
            }
        }
    }
    
    // MARK: - Status Indicator Functions
    
    private func getCompletionStatus(for exercise: Exercise) -> (completed: Int, target: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            return (0, exercise.targetSets)
        }
        
        // Filter for today's sessions
        let todaySessions = allSessions.filter { session in
            calendar.isDate(calendar.startOfDay(for: session.date), inSameDayAs: today)
        }
        
        // Count completed sets for this exercise today
        var completedSets = 0
        for session in todaySessions {
            let exerciseSets = session.sets.filter { 
                $0.exercise?.persistentModelID == exercise.persistentModelID && $0.isCompleted 
            }
            completedSets += exerciseSets.count
        }
        
        return (completedSets, exercise.targetSets)
    }
    
    private func circleColor(for exercise: Exercise) -> Color {
        let status = getCompletionStatus(for: exercise)
        
        if status.completed == 0 {
            return Color(white: 0.4) // Grey - not started
        } else if status.completed >= status.target {
            return Color.green // Green - target met
        } else {
            return Color.yellow // Yellow - in progress
        }
    }
    
    // MARK: - Exercise Management
    
    private func deleteExercise(_ exercise: Exercise) {
        workoutDay.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
        
        do {
            try modelContext.save()
            print("Deleted exercise '\(exercise.name)'")
            
            // Haptic feedback for deletion
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        } catch {
            print("Error deleting exercise: \(error)")
        }
    }
    
    private func saveExerciseTargets() {
        guard let exercise = editingExercise else { return }
        
        exercise.targetSets = editTargetSets
        exercise.targetReps = editTargetReps
        
        do {
            try modelContext.save()
            print("Updated targets for '\(exercise.name)'")
            
            // Haptic feedback for successful save
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error saving targets: \(error)")
        }
        
        showingEditSheet = false
        editingExercise = nil
    }
}

private struct ExerciseRowContent: View {
    let day: WorkoutDay
    let exercise: Exercise
    let circleColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Target: \(exercise.targetSets) sets × \(exercise.targetReps) reps")
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(Color(white: 0.6))
            }
            
            Spacer()
            
            // Status circle - LEFT of chevron
            Circle()
                .fill(circleColor)
                .frame(width: 12, height: 12)
            

        }
        .padding(.vertical, 8)
    }
}
