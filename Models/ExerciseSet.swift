import Foundation
import SwiftData

// Represents a single performed set within a workout session for a specific exercise.
// Relationships:
// - Many-to-one to WorkoutSession via `session`
// - Many-to-one to Exercise via `exercise`
@Model
final class ExerciseSet {
    var session: WorkoutSession?
    var exercise: Exercise?

    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool

    init(session: WorkoutSession? = nil, exercise: Exercise? = nil, setNumber: Int, weight: Double, reps: Int, isCompleted: Bool = false) {
        self.session = session
        self.exercise = exercise
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
    }
}


