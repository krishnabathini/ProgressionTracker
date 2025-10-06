import Foundation
import SwiftData

// Classification of exercises to drive progressive overload percentage ranges.
enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case upperBody
    case lowerBody

    var id: String { rawValue }
}

// Represents an exercise template within a workout day, with targets.
// Relationships:
// - Many-to-one to WorkoutDay via `day`
// - One-to-many with ExerciseSet templates? Templates are not persisted here; actual sets live in WorkoutSession via ExerciseSet.
@Model
final class Exercise {
    // Back-reference to the owning day template
    var day: WorkoutDay?

    var name: String
    var targetSets: Int
    var targetReps: Int
    var exerciseType: ExerciseType

    init(day: WorkoutDay? = nil, name: String, targetSets: Int, targetReps: Int, exerciseType: ExerciseType) {
        self.day = day
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.exerciseType = exerciseType
    }
}


