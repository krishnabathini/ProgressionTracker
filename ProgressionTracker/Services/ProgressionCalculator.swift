import Foundation

/// Represents the progression status for an exercise based on recent performance.
enum ProgressionStatus {
    case readyToProgress   // Hit targets in the most recent session
    case maintain          // Mixed/steady performance, maintain current weight
    case needsDeload       // Failed to hit targets across recent sessions
}

/// Service responsible for calculating progressive overload recommendations
/// based on provided session history. This implementation intentionally avoids
/// SwiftData predicates — callers provide `[WorkoutSession]` (e.g., from `@Query`).
class ProgressionCalculator {

    // MARK: - Main Calculation Methods

    /// Determines if weight should be increased for an exercise based on the most recent session.
    /// - Parameters:
    ///   - exercise: The exercise to evaluate.
    ///   - sessions: All available sessions from the caller (e.g., `@Query`).
    /// - Returns: `true` if exactly 3 sets in the most recent session all meet or exceed the exercise's target reps.
    func shouldIncreaseWeight(for exercise: Exercise, sessions: [WorkoutSession]) -> Bool {
        // Filter to sessions that actually include sets for this exercise
        let exerciseSessions = sessions.filter { session in
            session.sets.contains { $0.exercise == exercise }
        }

        // Identify the most recent session by date
        guard let mostRecent = exerciseSessions.sorted(by: { $0.date > $1.date }).first else {
            return false // No matching sessions yet
        }

        // Pull the sets for this exercise from that session
        let setsForExercise = mostRecent.sets.filter { $0.exercise == exercise }

        // Check if we have exactly 3 sets and if ALL of them meet or exceed the exercise's specific target reps
        let lastThreeSets = Array(setsForExercise.suffix(3))
        return lastThreeSets.count == 3 && 
               lastThreeSets.allSatisfy { $0.reps >= exercise.targetReps }
    }

    /// Calculates the recommended next weight for an exercise.
    /// - Parameters:
    ///   - currentWeight: The current working weight.
    ///   - exerciseType: The exercise type (upper vs lower body) to determine increment.
    /// - Returns: The next weight rounded to the nearest 2.5 lbs.
    func calculateNextWeight(currentWeight: Double, exerciseType: ExerciseType) -> Double {
        let multiplier: Double = (exerciseType == .upperBody) ? 1.025 : 1.05
        let increased = currentWeight * multiplier
        let rounded = (increased / 2.5).rounded() * 2.5
        return rounded
    }

    /// Returns a user-friendly recommendation message for the next session.
    /// - Parameters:
    ///   - exercise: The exercise being performed.
    ///   - currentWeight: The current working weight.
    ///   - sessions: All available sessions from the caller (e.g., `@Query`).
    func getRecommendation(for exercise: Exercise, currentWeight: Double, sessions: [WorkoutSession]) -> String {
        // Filter sessions for this specific exercise
        let exerciseSessions = sessions.filter { session in
            session.sets.contains { $0.exercise == exercise }
        }
        
        // Sort sessions by most recent
        let sortedSessions = exerciseSessions.sorted { $0.date > $1.date }
        
        // Find the most recent session with sets for this exercise
        guard let mostRecentSession = sortedSessions.first else {
            return "Start with \(String(format: "%.1f", currentWeight)) lbs for \(exercise.targetReps) reps"
        }
        
        // Get sets for this exercise in the most recent session
        let exerciseSets = mostRecentSession.sets.filter { $0.exercise == exercise }
        
        // Ensure we have at least 3 sets
        guard exerciseSets.count >= 3 else {
            return "Maintain \(String(format: "%.1f", currentWeight)) lbs - aim for \(exercise.targetReps) reps"
        }
        
        // Take the last 3 sets
        let lastThreeSets = Array(exerciseSets.suffix(3))
        
        // Check if ALL last 3 sets met or exceeded target reps at the current weight
        let allSetsMetTarget = lastThreeSets.allSatisfy { 
            $0.reps >= exercise.targetReps && 
            $0.weight == currentWeight 
        }
        
        // If all sets met target, calculate next weight
        if allSetsMetTarget {
            let nextWeight = calculateNextWeight(
                currentWeight: currentWeight, 
                exerciseType: exercise.exerciseType
            )
            return "Great job! Try \(String(format: "%.1f", nextWeight)) lbs × \(exercise.targetReps) reps"
        } else {
            return "Maintain \(String(format: "%.1f", currentWeight)) lbs - aim for \(exercise.targetReps) reps"
        }
    }

    /// Determines progression status based on the last three sessions for the exercise.
    /// - Parameters:
    ///   - exercise: The exercise to evaluate.
    ///   - sessions: All available sessions from the caller (e.g., `@Query`).
    /// - Returns: A `ProgressionStatus` based on recent performance.
    func getProgressionStatus(for exercise: Exercise, sessions: [WorkoutSession]) -> ProgressionStatus {
        // Filter to only sessions that include sets for this exercise
        let exerciseSessions = sessions.filter { session in
            session.sets.contains { $0.exercise == exercise }
        }

        // Sort by most recent first and take the most recent three
        let recentThree = Array(exerciseSessions.sorted(by: { $0.date > $1.date }).prefix(3))

        // If there's no history, default to maintain
        guard !recentThree.isEmpty else { return .maintain }

        // Compute whether each session hit all targets using the same logic as `shouldIncreaseWeight`
        let hitTargets: [Bool] = recentThree.map { session in
            let setsForExercise = session.sets.filter { $0.exercise == exercise }
            return !setsForExercise.isEmpty && setsForExercise.allSatisfy { $0.reps >= exercise.targetReps }
        }

        // Rule set:
        // - If the most recent session hit targets => readyToProgress
        // - If all three recent sessions failed => needsDeload
        // - Otherwise => maintain
        if let mostRecentHit = hitTargets.first, mostRecentHit {
            return .readyToProgress
        }

        if hitTargets.count == 3 && hitTargets.allSatisfy({ $0 == false }) {
            return .needsDeload
        }

        return .maintain
    }
}
