import SwiftUI
import SwiftData

/// Main workout logging screen where users log sets and receive progressive overload recommendations
/// This is a basic skeleton - functionality will be added piece by piece
struct ExerciseTrackingView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Validation state
    @State private var isValidExercise: Bool = true
    @State private var validationError: String?
    
    // Input control state variables
    @State private var currentWeight: Double = 0.0
    @State private var currentReps: Int = 8
    @State private var setNumber: Int = 1
    
    // Session management state variables
    @State private var currentSession: WorkoutSession?
    @State private var completedSets: [ExerciseSet] = []
    @State private var recommendation: String = ""
    @State private var workoutHistory: [(date: Date, sets: [ExerciseSet])] = []
    @State private var previousMetrics: (volume: Double, avgReps: Double, lbsPerRep: Double)?
    
    // Weight input state variables
    @State private var showWeightInput = false
    @State private var weightInputText = ""
    @State private var showEditWeightInput = false
    @State private var editWeightInputText = ""
    
    // Edit state variables
    @State private var editingSet: ExerciseSet?
    
    
    // MARK: - Validation
    
    /// Validates the exercise data without crashing
    private func validateExercise() {
        // Check exercise name
        if exercise.name.isEmpty {
            validationError = "Exercise name cannot be empty"
            isValidExercise = false
            return
        }
        
        // Check target sets
        if exercise.targetSets <= 0 {
            validationError = "Target sets must be greater than 0"
            isValidExercise = false
            return
        }
        
        // Check target reps
        if exercise.targetReps <= 0 {
            validationError = "Target reps must be greater than 0"
            isValidExercise = false
            return
        }
        
        // All validations passed
        isValidExercise = true
        validationError = nil
    }
    
    // MARK: - Session Management
    
    private func findOrCreateSession() {
        // Get today's date (start of day)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // OPTIMIZATION: Only fetch sessions from last 7 days for faster search
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        // Fetch recent sessions only
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allSessions = try modelContext.fetch(descriptor)
            // Filter to last 7 days only
            let recentSessions = allSessions.filter { $0.date >= sevenDaysAgo }
            
            // Filter in Swift code to find session for today's workout day
            let todaysSession = recentSessions.first { session in
                let sessionDate = calendar.startOfDay(for: session.date)
                let isToday = sessionDate == today
                let isSameWorkoutDay = session.day?.persistentModelID == exercise.day?.persistentModelID
                return isToday && isSameWorkoutDay
            }
            
            if let existingSession = todaysSession {
                currentSession = existingSession
                // Load completed sets for this exercise from the session
                completedSets = existingSession.sets.filter { set in
                    guard let setExercise = set.exercise else { return false }
                    return setExercise.persistentModelID == exercise.persistentModelID
                }
                setNumber = completedSets.count + 1
            } else {
                // Create new session for today
                let newSession = WorkoutSession(
                    program: exercise.day?.program,
                    day: exercise.day,
                    date: Date(),
                    notes: nil
                )
                modelContext.insert(newSession)
                currentSession = newSession
                completedSets = []
                setNumber = 1
            }
        } catch {
            print("Error fetching sessions: \(error)")
            // Fallback: create new session for today's workout day
            let newSession = WorkoutSession(
                program: exercise.day?.program,
                day: exercise.day,
                date: Date(),
                notes: nil
            )
            modelContext.insert(newSession)
            currentSession = newSession
            completedSets = []
            setNumber = 1
        }
        
        // Calculate progression recommendation
        updateRecommendation()
    }
    
    private func addSet() {
        guard let session = currentSession else {
            print("ERROR: No current session available")
            return
        }
        
        // Validate input
        guard currentWeight >= 0 else {
            return
        }
        
        guard currentReps > 0 else {
            return
        }
        
        // Create new exercise set
        let newSet = ExerciseSet(
            session: session,
            exercise: exercise,
            setNumber: setNumber,
            weight: currentWeight,
            reps: currentReps,
            isCompleted: true
        )
        
        // Insert into model context
        modelContext.insert(newSet)
        
        // Add to completed sets array
        completedSets.append(newSet)
        
        // Increment set number for next set
        setNumber += 1
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("ERROR saving set: \(error.localizedDescription)")
            // Remove from array if save failed
            completedSets.removeLast()
            setNumber -= 1
            return
        }
        
        // Recalculate recommendation after adding set
        updateRecommendation()
        
        // Reload workout history and metrics to reflect new set
        loadWorkoutHistory()
        loadPreviousMetrics()
        
        // Reset reps to target for next set
        currentReps = exercise.targetReps
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func updateRecommendation() {
        // Guard against empty sets array
        guard !completedSets.isEmpty else {
            recommendation = ""
            return
        }
        
        // Recalculate recommendation after adding set
        let calculator = ProgressionCalculator()
        if completedSets.count >= 3 {
            // Get last 3 sets
            let lastThreeSets = Array(completedSets.suffix(3))
            
            // Check if last 3 sets are at the SAME weight
            let weights = lastThreeSets.map { $0.weight }
            let allSameWeight = Set(weights).count == 1
            
            // Check if all 3 sets hit target reps
            let allHitTargetReps = lastThreeSets.allSatisfy { $0.reps >= exercise.targetReps }
            
            // Safe unwrapping of last set
            guard let lastSet = completedSets.last else {
                return
            }
            let currentSetWeight = lastSet.weight
            
            if allSameWeight && allHitTargetReps {
                // User completed 3 sets at same weight with target reps - progress!
                let nextWeight = calculator.calculateNextWeight(
                    currentWeight: currentSetWeight,
                    exerciseType: exercise.exerciseType
                )
                recommendation = "Try \(String(format: "%.1f", nextWeight)) lbs × \(exercise.targetReps) reps"
                currentWeight = nextWeight
            } else {
                // Haven't completed 3 sets at same weight yet - maintain
                recommendation = "Maintain \(String(format: "%.1f", currentSetWeight)) lbs × \(exercise.targetReps) reps"
                currentWeight = currentSetWeight
            }
        } else {
            // Less than 3 sets completed - maintain current weight
            if let lastWeight = completedSets.last?.weight {
                recommendation = "Maintain \(String(format: "%.1f", lastWeight)) lbs × \(exercise.targetReps) reps"
                currentWeight = lastWeight
            }
        }
    }
    
    private func deleteSet(_ set: ExerciseSet) {
        if let index = completedSets.firstIndex(where: { $0.persistentModelID == set.persistentModelID }) {
            completedSets.remove(at: index)
            modelContext.delete(set)
            
            // Renumber remaining sets
            for (idx, remainingSet) in completedSets.enumerated() {
                remainingSet.setNumber = idx + 1
            }
            
            setNumber = completedSets.count + 1
            try? modelContext.save()
            
            // Recalculate recommendation after deleting set
            updateRecommendation()
            
            // Reload workout history and metrics to reflect deletion
            loadWorkoutHistory()
            loadPreviousMetrics()
            
            // Haptic feedback for deletion
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
    }
    
    private func getCurrentWorkoutMetrics() -> (volume: Double, avgReps: Double, lbsPerRep: Double) {
        guard !completedSets.isEmpty else {
            return (0, 0, 0)
        }
        
        let volume = completedSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        let avgReps = Double(completedSets.reduce(0) { $0 + $1.reps }) / Double(completedSets.count)
        let totalReps = completedSets.reduce(0) { $0 + $1.reps }
        let lbsPerRep = totalReps > 0 ? volume / Double(totalReps) : 0
        
        return (volume, avgReps, lbsPerRep)
    }
    
    private func getPreviousWorkoutMetrics() -> (volume: Double, avgReps: Double, lbsPerRep: Double)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // OPTIMIZATION: Only look at last 30 days for previous workout
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            return nil
        }
        
        // Filter to last 30 days only
        let recentSessions = allSessions.filter { $0.date >= thirtyDaysAgo }
        
        // Find the most recent session before today with this exercise
        for session in recentSessions {
            let sessionDate = calendar.startOfDay(for: session.date)
            
            // Skip today's sessions
            if calendar.isDate(sessionDate, inSameDayAs: today) {
                continue
            }
            
            // Check if this session has sets for this exercise
            let exerciseSets = session.sets.filter { set in
                guard let setExercise = set.exercise else { return false }
                return setExercise.persistentModelID == exercise.persistentModelID && set.isCompleted
            }
            
            if !exerciseSets.isEmpty {
                let volume = exerciseSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                let avgReps = Double(exerciseSets.reduce(0) { $0 + $1.reps }) / Double(exerciseSets.count)
                let totalReps = exerciseSets.reduce(0) { $0 + $1.reps }
                let lbsPerRep = totalReps > 0 ? volume / Double(totalReps) : 0
                
                return (volume, avgReps, lbsPerRep)
            }
        }
        
        return nil
    }
    
    private func loadWorkoutHistory() {
        workoutHistory = fetchAllWorkoutHistory()
    }
    
    private func loadPreviousMetrics() {
        // Use the enhanced volume metrics calculation with set matching
        updateVolumeMetrics()
    }
    
    // MARK: - Recommendation Diagnostics
    
    /// Fetches recent sessions (last 30 days) for diagnostics.
    private func fetchSessionsForDiagnostics() -> [WorkoutSession] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            print("⚠️ Diagnostics: Unable to fetch sessions from context.")
            return []
        }
        
        let recentSessions = allSessions.filter { $0.date >= thirtyDaysAgo }
        print("🗂️ Diagnostics: Found \(recentSessions.count) recent sessions for analysis.")
        return recentSessions
    }
    
    /// Provides detailed logging while attempting to generate an initial recommendation.
    private func getInitialRecommendation(for exercise: Exercise, sessions: [WorkoutSession]) -> (weight: Double, reps: Int)? {
        print("🔍 Generating Initial Recommendation")
        print("Exercise: \(exercise.name)")
        print("Exercise Type: \(exercise.exerciseType)")
        print("Target Reps: \(exercise.targetReps)")
        
        let exerciseSessions = sessions.filter { session in
            let exerciseSets = session.sets.filter { set in
                guard let setExercise = set.exercise else { return false }
                return setExercise.persistentModelID == exercise.persistentModelID && set.isCompleted
            }
            print("Session \(session.date): \(exerciseSets.count) sets for exercise.")
            return !exerciseSets.isEmpty
        }
        
        print("Total Relevant Sessions: \(exerciseSessions.count)")
        
        exerciseSessions.forEach { session in
            print("📅 Session Date: \(session.date)")
            let exerciseSets = session.sets.filter { set in
                guard let setExercise = set.exercise else { return false }
                return setExercise.persistentModelID == exercise.persistentModelID && set.isCompleted
            }
            exerciseSets.forEach { set in
                print("   • Set \(set.setNumber): \(set.reps) reps @ \(set.weight) lbs")
            }
        }
        
        // No previous sessions - suggest a sensible starting point.
        guard !exerciseSessions.isEmpty else {
            let startingWeight = suggestInitialWeight(for: exercise)
            print("✅ Initial suggestion (no history): \(startingWeight) lbs")
            return (weight: startingWeight, reps: exercise.targetReps)
        }
        
        // Use the most recent session to derive next steps
        let sortedSessions = exerciseSessions.sorted { $0.date > $1.date }
        
        guard let mostRecentSession = sortedSessions.first else {
            print("❗ No previous sets found. Using default recommendation.")
            let startingWeight = suggestInitialWeight(for: exercise)
            return (weight: startingWeight, reps: exercise.targetReps)
        }
        
        let exerciseSets = mostRecentSession.sets
            .filter { set in
                guard let setExercise = set.exercise else { return false }
                return setExercise.persistentModelID == exercise.persistentModelID && set.isCompleted
            }
            .sorted(by: { $0.setNumber < $1.setNumber })
        
        guard exerciseSets.count == 3 else {
            print("⚠️ Most recent session does not have 3 completed sets. Maintaining current weight.")
            let fallbackWeight = exerciseSets.last?.weight ?? suggestInitialWeight(for: exercise)
            return (weight: fallbackWeight, reps: exercise.targetReps)
        }
        
        guard
            let firstSetWeight = exerciseSets.first?.weight,
            exerciseSets.allSatisfy({ $0.weight == firstSetWeight && $0.reps >= exercise.targetReps })
        else {
            print("ℹ️ Not all sets met target reps or weights are inconsistent. Maintaining current weight.")
            let fallbackWeight = exerciseSets.last?.weight ?? suggestInitialWeight(for: exercise)
            return (weight: fallbackWeight, reps: exercise.targetReps)
        }
        
        let currentWeight = firstSetWeight
        var nextWeight: Double
        
        if currentWeight < 25.0 {
            nextWeight = currentWeight + 2.5
            print("💡 Low weight increment applied: +2.5 lbs (from \(currentWeight) → \(nextWeight))")
        } else {
            let multiplier: Double = (exercise.exerciseType == .upperBody) ? 1.025 : 1.05
            nextWeight = (currentWeight * multiplier / 2.5).rounded() * 2.5
            print("💡 Percentage increment applied (multiplier \(multiplier)): \(currentWeight) → \(nextWeight)")
        }
        
        print("🏆 Recommendation: \(nextWeight) lbs × \(exercise.targetReps) reps")
        return (weight: nextWeight, reps: exercise.targetReps)
    }
    
    /// Loads the diagnostic recommendation banner for initial guidance.
    private func loadInitialRecommendation() {
        print("🚀 Loading Initial Recommendation Banner")
        
        let previousSessions = fetchSessionsForDiagnostics()
        print("Total Previous Sessions (All): \(previousSessions.count)")
        
        guard let initialRec = getInitialRecommendation(for: exercise, sessions: previousSessions) else {
            print("❌ No Initial Recommendation Generated - defaulting banner.")
            if recommendation.isEmpty {
                recommendation = "Start your workout"
            }
            return
        }
        
        print("✅ Initial Recommendation Generated: \(initialRec.weight) lbs × \(initialRec.reps) reps")
        if recommendation.isEmpty {
            recommendation = "Try \(String(format: "%.1f", initialRec.weight)) lbs × \(initialRec.reps) reps"
        }
    }
    
    private func suggestInitialWeight(for exercise: Exercise) -> Double {
        switch exercise.exerciseType {
        case .upperBody:
            if exercise.name.lowercased().contains("bench") {
                return 45.0
            } else if exercise.name.lowercased().contains("press") {
                return 35.0
            } else {
                return 12.5
            }
        case .lowerBody:
            if exercise.name.lowercased().contains("squat") {
                return 95.0
            } else if exercise.name.lowercased().contains("deadlift") {
                return 115.0
            } else {
                return 65.0
            }
        }
    }
    
    // MARK: - Volume Metrics Calculation
    
    /// Fetches previous workout sessions for this exercise
    private func fetchPreviousSessions(for exercise: Exercise) -> [WorkoutSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // OPTIMIZATION: Only look at last 30 days for previous workout
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        // Filter to last 30 days only
        let recentSessions = allSessions.filter { $0.date >= thirtyDaysAgo }
        
        // Find the most recent session before today with this exercise
        for session in recentSessions {
            let sessionDate = calendar.startOfDay(for: session.date)
            
            // Skip today's sessions
            if calendar.isDate(sessionDate, inSameDayAs: today) {
                continue
            }
            
            // Check if this session has sets for this exercise
            let exerciseSets = session.sets.filter { set in
                guard let setExercise = set.exercise else { return false }
                return setExercise.persistentModelID == exercise.persistentModelID && set.isCompleted
            }
            
            if !exerciseSets.isEmpty {
                return [session]
            }
        }
        
        return []
    }
    
    /// Gets previous sets from previous workout sessions, sorted by set number
    private func getPreviousSets(from sessions: [WorkoutSession]) -> [ExerciseSet] {
        guard let previousSession = sessions.first else {
            return []
        }
        
        let previousSets = previousSession.sets.filter { set in
            guard let setExercise = set.exercise else { return false }
            return setExercise.persistentModelID == exercise.persistentModelID && set.isCompleted
        }
        
        // Sort by set number to ensure proper matching
        return previousSets.sorted { $0.setNumber < $1.setNumber }
    }
    
    /// Gets current workout sets sorted by set number
    private func getCurrentWorkoutSets() -> [ExerciseSet] {
        return completedSets.sorted { $0.setNumber < $1.setNumber }
    }
    
    /// Calculates volume metrics by comparing only matching set numbers
    /// This ensures accurate progression tracking as sets are added dynamically
    func calculateVolumeMetrics(
        currentSets: [ExerciseSet],
        previousSets: [ExerciseSet]
    ) -> (volume: Double, volumeDifference: Double) {
        // Determine the number of sets to compare
        let comparisonSetCount = currentSets.count
        
        // If no current sets, return zero volume
        guard comparisonSetCount > 0 else {
            return (volume: 0.0, volumeDifference: 0.0)
        }
        
        // Calculate current workout volume for current sets
        let currentVolume = currentSets.reduce(0.0) {
            $0 + ($1.weight * Double($1.reps))
        }
        
        // Calculate previous workout volume for matching number of sets
        let previousVolume = previousSets.prefix(comparisonSetCount).reduce(0.0) {
            $0 + ($1.weight * Double($1.reps))
        }
        
        // Calculate volume difference
        let volumeDifference = currentVolume - previousVolume
        
        return (
            volume: currentVolume,
            volumeDifference: volumeDifference
        )
    }
    
    /// Calculates normalized bar widths for volume display
    /// Prevents UI overflow while maintaining proportional representation
    /// - Parameters:
    ///   - currentVolume: The current workout volume
    ///   - previousVolume: The previous workout volume for comparison
    ///   - maxWidth: Maximum available width for the bar (from GeometryReader)
    ///   - padding: Additional padding to prevent edge overflow (default: 0)
    /// - Returns: Tuple containing normalized current and previous bar widths
    private func calculateBarWidths(
        currentVolume: Double,
        previousVolume: Double,
        maxWidth: CGFloat,
        padding: CGFloat = 0
    ) -> (currentWidth: CGFloat, previousWidth: CGFloat) {
        // Prevent division by zero
        guard maxWidth > 0 else {
            return (currentWidth: 0, previousWidth: 0)
        }
        
        // Find the maximum volume to use as reference
        let maxVolume = max(currentVolume, previousVolume)
        
        // If no volume, return zero widths
        guard maxVolume > 0 else {
            return (currentWidth: 0, previousWidth: 0)
        }
        
        // Calculate available width (accounting for padding)
        let availableWidth = max(maxWidth - padding, 0)
        
        // Scale volumes proportionally to available width
        let scaledCurrentWidth = (currentVolume / maxVolume) * availableWidth
        let scaledPreviousWidth = (previousVolume / maxVolume) * availableWidth
        
        // Ensure widths don't exceed available space and have minimum visibility
        let minWidth: CGFloat = 2.0 // Minimum width for visibility
        let currentWidth = min(max(scaledCurrentWidth, minWidth), availableWidth)
        let previousWidth = min(max(scaledPreviousWidth, minWidth), availableWidth)
        
        return (
            currentWidth: currentWidth,
            previousWidth: previousWidth
        )
    }
    
    /// Updates volume metrics using the enhanced set-matching calculation
    private func updateVolumeMetrics() {
        // Fetch previous workout sessions for this exercise
        let previousSessions = fetchPreviousSessions(for: exercise)
        
        // Get sets from previous workouts (sorted by set number)
        let previousSets = getPreviousSets(from: previousSessions)
        
        // Update previousMetrics with the matched volume comparison
        if !previousSets.isEmpty {
            // Calculate full previous metrics for display
            let previousVolume = previousSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            let previousAvgReps = Double(previousSets.reduce(0) { $0 + $1.reps }) / Double(previousSets.count)
            let previousTotalReps = previousSets.reduce(0) { $0 + $1.reps }
            let previousLbsPerRep = previousTotalReps > 0 ? previousVolume / Double(previousTotalReps) : 0
            
            previousMetrics = (previousVolume, previousAvgReps, previousLbsPerRep)
        } else {
            previousMetrics = nil
        }
    }
    
    private func fetchAllWorkoutHistory() -> [(date: Date, sets: [ExerciseSet])] {
        let calendar = Calendar.current
        
        // OPTIMIZATION: Only fetch last 30 days of workouts for faster loading
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allSessions = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        // Filter to last 30 days only
        let recentSessions = allSessions.filter { $0.date >= thirtyDaysAgo }
        
        var groupedByDate: [Date: [ExerciseSet]] = [:]
        
        for session in recentSessions {
            guard !session.sets.isEmpty else { continue }
            
            let exerciseSets = session.sets.filter { set in
                guard let setExercise = set.exercise else { return false }
                return setExercise.persistentModelID == exercise.persistentModelID && set.isCompleted
            }
            
            if !exerciseSets.isEmpty {
                let dateKey = calendar.startOfDay(for: session.date)
                groupedByDate[dateKey, default: []].append(contentsOf: exerciseSets)
            }
        }
        
        // Convert to array and sort by date (newest first)
        return groupedByDate.map { (date: $0.key, sets: $0.value.sorted { $0.setNumber < $1.setNumber }) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        Group {
            if !isValidExercise {
                // Show error view if exercise data is invalid
                errorView
            } else {
                // Show normal exercise tracking view
                mainContent
            }
        }
        .onAppear {
            validateExercise()
            if isValidExercise {
                currentReps = exercise.targetReps
                findOrCreateSession()
                loadWorkoutHistory()
                loadPreviousMetrics()
                loadInitialRecommendation()
            }
        }
    }
    
    // MARK: - Bottom Editing Card
    
    @ViewBuilder
    private var bottomEditingCard: some View {
        if let editingSet = editingSet {
            SetEditingCard(
                set: editingSet,
                exerciseName: exercise.name,
                onUpdate: {
                    try? modelContext.save()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.editingSet = nil
                    }
                },
                onDismiss: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.editingSet = nil
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Invalid Exercise Data")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let error = validationError {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button("Go Back") {
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .background(Color(hex: "1C1C1E"))
            .navigationTitle("Error")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 4) {
                        // Recommendation banner (if exists)
                        if !recommendation.isEmpty {
                            Text(recommendation)
                                .font(.system(.body, design: .default, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(recommendation.starts(with: "Try") ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                        }
                        
                        // Metrics (if any sets completed)
                        if !completedSets.isEmpty {
                            let current = getCurrentWorkoutMetrics()
                            let previous = previousMetrics
                            
                            // Calculate matched volume metrics for accurate comparison
                            let previousSessions = fetchPreviousSessions(for: exercise)
                            let currentSets = getCurrentWorkoutSets()
                            let previousSets = getPreviousSets(from: previousSessions)
                            let matchedMetrics = calculateVolumeMetrics(
                                currentSets: currentSets,
                                previousSets: previousSets
                            )
                            
                            VStack(spacing: 16) {
                                // Volume
                                HStack {
                                    Text("VOLUME")
                                        .font(.system(.caption, design: .default, weight: .medium))
                                        .foregroundStyle(Color(white: 0.5))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(current.volume))lbs")
                                        .font(.system(.title3, design: .default, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    // Show matched volume difference (only comparing sets with matching set numbers)
                                    if !previousSets.isEmpty {
                                        // Always use matched volume difference when previous sets exist
                                        // This compares only the matching number of sets
                                        if abs(matchedMetrics.volumeDifference) > 0.5 {
                                            // Only show if difference is meaningful (more than 0.5 lbs)
                                            HStack(spacing: 4) {
                                                Image(systemName: matchedMetrics.volumeDifference > 0 ? "arrow.up" : "arrow.down")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text("\(Int(abs(matchedMetrics.volumeDifference)))lbs")
                                                    .font(.system(.caption, design: .default, weight: .semibold))
                                            }
                                            .foregroundStyle(matchedMetrics.volumeDifference > 0 ? .green : .red)
                                        }
                                    } else if let prev = previous {
                                        // Fallback to total volume comparison if no previous matched sets
                                        let diff = current.volume - prev.volume
                                        if abs(diff) > 0.5 {
                                        HStack(spacing: 4) {
                                            Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                                                .font(.system(size: 12, weight: .bold))
                                            Text("\(Int(abs(diff)))lbs")
                                                .font(.system(.caption, design: .default, weight: .semibold))
                                        }
                                        .foregroundStyle(diff > 0 ? .green : .red)
                                        }
                                    }
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background bar
                                        Rectangle()
                                            .fill(Color(white: 0.2))
                                            .frame(height: 8)
                                        
                                        if !previousSets.isEmpty && matchedMetrics.volume > 0 {
                                            // Use matched volume for comparison with normalized scaling
                                            let comparisonSetCount = currentSets.count
                                            let matchedPreviousVolume = previousSets.prefix(comparisonSetCount)
                                                .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                                            
                                            if matchedPreviousVolume > 0 {
                                                // Calculate normalized bar widths to prevent overflow
                                                let barWidths = calculateBarWidths(
                                                    currentVolume: matchedMetrics.volume,
                                                    previousVolume: matchedPreviousVolume,
                                                    maxWidth: geometry.size.width,
                                                    padding: 0
                                                )
                                                
                                                // Display current volume bar with normalized width
                                                Rectangle()
                                                    .fill(matchedMetrics.volume >= matchedPreviousVolume ? Color.green : Color.red)
                                                    .frame(width: barWidths.currentWidth, height: 8)
                                            } else {
                                                // No previous volume - show current as full bar
                                                Rectangle()
                                                    .fill(Color.green)
                                                    .frame(width: geometry.size.width, height: 8)
                                            }
                                        } else if let prev = previous, prev.volume > 0 {
                                            // Fallback to total volume comparison with normalized scaling
                                            let barWidths = calculateBarWidths(
                                                currentVolume: current.volume,
                                                previousVolume: prev.volume,
                                                maxWidth: geometry.size.width,
                                                padding: 0
                                            )
                                            
                                            Rectangle()
                                                .fill(current.volume >= prev.volume ? Color.green : Color.red)
                                                .frame(width: barWidths.currentWidth, height: 8)
                                        } else {
                                            // No previous workout - show current as full bar in green
                                            Rectangle()
                                                .fill(Color.green)
                                                .frame(width: geometry.size.width, height: 8)
                                        }
                                    }
                                    .cornerRadius(4)
                                }
                                .frame(height: 8)
                                
                                // Reps per set
                                HStack {
                                    Text("REPS PER SET")
                                        .font(.system(.caption, design: .default, weight: .medium))
                                        .foregroundStyle(Color(white: 0.5))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(current.avgReps))")
                                        .font(.system(.title3, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                                    
                                    if let prev = previous {
                                        let diff = current.avgReps - prev.avgReps
                                        
                                        // Only show comparison if there's a meaningful difference
                                        if abs(diff) >= 0.5 {
                                            let isImprovement = current.avgReps >= Double(exercise.targetReps) || diff > 0
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(String(format: "%.1f", abs(diff)))
                                                    .font(.system(.caption, design: .default, weight: .semibold))
                                            }
                                            .foregroundStyle(isImprovement ? .green : .red)
                                        }
                                    }
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(white: 0.2))
                                            .frame(height: 8)
                                        
                                        if let prev = previous, prev.avgReps > 0 {
                                            let ratio = current.avgReps / prev.avgReps
                                            let progress = min(max(ratio, 0.1), 1.0)  // Cap at 1.0 for display
                                            Rectangle()
                                                .fill(current.avgReps >= prev.avgReps ? Color.green : Color.red)
                                                .frame(width: geometry.size.width * progress, height: 8)
                                        } else {
                                            Rectangle()
                                                .fill(Color.green)
                                                .frame(width: geometry.size.width, height: 8)
                                        }
                                    }
                                    .cornerRadius(4)
                                }
                                .frame(height: 8)
                                
                                // Lbs per rep
                                HStack {
                                    Text("LBS PER REP")
                                        .font(.system(.caption, design: .default, weight: .medium))
                                        .foregroundStyle(Color(white: 0.5))
                
                Spacer()
                
                                    Text(String(format: "%.1flbs", current.lbsPerRep))
                                        .font(.system(.title3, design: .default, weight: .bold))
                                        .foregroundStyle(.white)
                                    
                                    if let prev = previous {
                                        let diff = current.lbsPerRep - prev.lbsPerRep
                                        HStack(spacing: 4) {
                                            Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                                                .font(.system(size: 12, weight: .bold))
                                            Text(String(format: "%.1flbs", abs(diff)))
                                                .font(.system(.caption, design: .default, weight: .semibold))
                                        }
                                        .foregroundStyle(diff > 0 ? .green : .red)
                                    }
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(white: 0.2))
                                            .frame(height: 8)
                                        
                                        if let prev = previous, prev.lbsPerRep > 0 {
                                            let ratio = current.lbsPerRep / prev.lbsPerRep
                                            let progress = min(max(ratio, 0.1), 1.0)  // Cap at 1.0 for display
                                            Rectangle()
                                                .fill(current.lbsPerRep >= prev.lbsPerRep ? Color.green : Color.red)
                                                .frame(width: geometry.size.width * progress, height: 8)
                                        } else {
                                            Rectangle()
                                                .fill(Color.green)
                                                .frame(width: geometry.size.width, height: 8)
                                        }
                                    }
                                    .cornerRadius(4)
                                }
                                .frame(height: 8)
                            }
                            .padding()
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        
                        // Set history grouped by date
                        if workoutHistory.isEmpty {
                            VStack {
                                Text("No sets completed yet")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)
                                    .padding()
                            }
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        } else {
                            ForEach(workoutHistory, id: \.date) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Date header
                                    Text(group.date, format: .dateTime.month(.wide).day().year())
                                        .font(.system(.caption, design: .default, weight: .medium))
                                        .foregroundStyle(Color(white: 0.5))
                                        .textCase(.uppercase)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.top, group.date == workoutHistory.first?.date ? 0 : 16)
                                    
                                    // Container with sets for this date
                                    List {
                                        ForEach(group.sets) { set in
                                            let isToday = Calendar.current.isDateInToday(group.date)
                                            
                                                // NORMAL MODE (read-only for past dates, editable for today)
                                                VStack(spacing: 0) {
                                                    HStack {
                                                        Text("SET \(set.setNumber)")
                                                            .font(.system(.subheadline, design: .default, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                                                        Text("\(set.reps) reps × \(String(format: "%.1f", set.weight)) lbs")
                                                            .font(.system(.subheadline, design: .default))
                                                            .foregroundStyle(Color(white: 0.7))
                                                    }
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        if isToday {
                                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                            editingSet = set
                                                        }
                                                        }
                                                    }
                                                    
                                                    if set.setNumber != group.sets.last?.setNumber {
                                                        Divider()
                                                            .background(Color(white: 0.3))
                                                            .padding(.top, 12)
                                                    }
                                                }
                                                .listRowBackground(Color.clear)
                                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))
                                                .listRowSeparator(.hidden)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    if isToday {
                                                        Button(role: .destructive) {
                                                            deleteSet(set)
                                                        } label: {
                                                            Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .listStyle(.plain)
                                    .scrollDisabled(true)
                                    .scrollContentBackground(.hidden)
                                    .environment(\.defaultMinListRowHeight, 0)
                                    .background(Color(hex: "2C2C2E"))
                                    .cornerRadius(12)
                                    .frame(height: CGFloat(group.sets.count * 44) + 12)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
                
                // Fixed input controls at bottom
                VStack(spacing: 10) {
                    // REPS
                    HStack {
                        Text("REPS")
                            .font(.system(.caption, design: .default, weight: .semibold))
                            .foregroundStyle(Color(white: 0.6))
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Button {
                                if currentReps > 1 { currentReps -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                            
                            Text("\(currentReps)")
                                .font(.system(size: 28, weight: .bold))
                                .frame(width: 50)
                                .foregroundStyle(.white)
                            
                            Button {
                                if currentReps < 50 { currentReps += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(10)
                    
                    // WEIGHT
                    HStack {
                        Text("WEIGHT")
                            .font(.system(.caption, design: .default, weight: .semibold))
                            .foregroundStyle(Color(white: 0.6))
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Button {
                                if currentWeight >= 2.5 { currentWeight -= 2.5 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                            
                            HStack(alignment: .lastTextBaseline, spacing: 6) {
                                Text(currentWeight == 0 ? "0" : String(format: "%.1f", currentWeight))
                                    .font(.system(size: 28, weight: .bold))
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                    .foregroundStyle(currentWeight == 0 ? Color(white: 0.4) : .white)
                                    .onTapGesture {
                                        weightInputText = ""
                                        showWeightInput = true
                                    }
                                
                                Text("lbs")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(white: 0.6))
                            }
                            
                            Button {
                                if currentWeight < 1000 { currentWeight += 2.5 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(10)
                    
                    // Add Set button
                    Button {
                        addSet()
                    } label: {
                        Text("Add Set")
                            .font(.system(.body, design: .default, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(16)
                .background(Color(hex: "1C1C1E"))
            }
            .background(Color(hex: "1C1C1E"))
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                bottomEditingCard
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: editingSet?.persistentModelID)
            }
            .onAppear {
                // This removes the text from the back button
                UINavigationBar.appearance().topItem?.backButtonDisplayMode = .minimal
            }
            .alert("Enter Weight", isPresented: $showWeightInput) {
                TextField("", text: $weightInputText)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) { 
                    weightInputText = "" 
                }
                Button("Set") {
                    if let weight = Double(weightInputText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        currentWeight = weight
                    }
                    weightInputText = ""
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutProgram.self, WorkoutDay.self, Exercise.self, configurations: config)
    
    let program = WorkoutProgram(name: "Push Pull Legs")
    let day = WorkoutDay(program: program, name: "Push Day", orderIndex: 0)
    let exercise = Exercise(day: day, name: "Bench Press", targetSets: 3, targetReps: 8, exerciseType: .upperBody)
    
    return ExerciseTrackingView(exercise: exercise)
        .modelContainer(container)
}

// MARK: - Set Editing Card

/// Bottom card for editing exercise sets - appears when user taps a set
struct SetEditingCard: View {
    @Bindable var set: ExerciseSet
    let exerciseName: String
    let onUpdate: () -> Void
    let onDismiss: () -> Void
    
    @State private var editWeight: Double
    @State private var editReps: Int
    @State private var showEditWeightInput = false
    @State private var editWeightInputText = ""
    
    init(set: ExerciseSet, exerciseName: String, onUpdate: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.set = set
        self.exerciseName = exerciseName
        self.onUpdate = onUpdate
        self.onDismiss = onDismiss
        _editWeight = State(initialValue: set.weight)
        _editReps = State(initialValue: set.reps)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise name header
            Text(exerciseName)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            VStack(spacing: 16) {
                // REPS section
                VStack(alignment: .leading, spacing: 8) {
                    Text("REPS")
                        .font(.system(.caption, design: .default, weight: .semibold))
                        .foregroundStyle(Color(white: 0.6))
                    
                    HStack(spacing: 12) {
                        Button {
                            if editReps > 1 { editReps -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Text("\(editReps)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 60)
                        
                        Spacer()
                        
                        Button {
                            if editReps < 50 { editReps += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // WEIGHT section
                VStack(alignment: .leading, spacing: 8) {
                    Text("WEIGHT")
                        .font(.system(.caption, design: .default, weight: .semibold))
                        .foregroundStyle(Color(white: 0.6))
                    
                    HStack(spacing: 12) {
                        Button {
                            if editWeight >= 2.5 {
                                editWeight -= 2.5
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", editWeight))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 80)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editWeightInputText = ""
                                showEditWeightInput = true
                            }
                        
                        Spacer()
                        
                        Button {
                            if editWeight < 1000 {
                                editWeight += 2.5
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .alert("Enter Weight", isPresented: $showEditWeightInput) {
                    TextField("Weight", text: $editWeightInputText)
                        .keyboardType(.decimalPad)
                    Button("Cancel", role: .cancel) {
                        editWeightInputText = ""
                    }
                    Button("Set") {
                        if let weight = Double(editWeightInputText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            editWeight = max(0, min(weight, 1000))
                        }
                        editWeightInputText = ""
                    }
                }
                
                // Update button
                Button {
                    set.weight = editWeight
                    set.reps = editReps
                    onUpdate()
                } label: {
                    Text("Update")
                        .font(.system(.body, design: .default, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.bottom, 20)
        }
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
