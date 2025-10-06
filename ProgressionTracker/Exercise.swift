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
// - Optional reference to ExerciseLibraryItem via `libraryItem` (when selected from library)
// - One-to-many with ExerciseSet templates? Templates are not persisted here; actual sets live in WorkoutSession via ExerciseSet.
@Model
final class Exercise {
    // Back-reference to the owning day template
    var day: WorkoutDay?

    var name: String
    var targetSets: Int
    var targetReps: Int
    var exerciseType: ExerciseType
    
    // Optional reference to the library item this exercise is based on
    // - If user selects from library: this links to the ExerciseLibraryItem
    // - If user creates custom: this remains nil
    // - Allows tracking which library exercise is being used across different workout days
    var libraryItem: ExerciseLibraryItem?

    init(day: WorkoutDay? = nil, name: String, targetSets: Int, targetReps: Int, exerciseType: ExerciseType, libraryItem: ExerciseLibraryItem? = nil) {
        self.day = day
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.exerciseType = exerciseType
        self.libraryItem = libraryItem
    }
}


