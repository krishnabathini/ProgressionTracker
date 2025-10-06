import Foundation
import SwiftData

// Represents a single logged workout instance for a program/day.
// Relationships:
// - Many-to-one to WorkoutProgram via `program`
// - Many-to-one to WorkoutDay via `day` (optional, in case of ad-hoc sessions)
// - One-to-many with ExerciseSet via `sets`
@Model
final class WorkoutSession {
    var program: WorkoutProgram?
    var day: WorkoutDay?

    var date: Date
    var notes: String?

    // Logged sets within this session
    // Inverse defined in `ExerciseSet.session`
    var sets: [ExerciseSet] = []

    init(program: WorkoutProgram? = nil, day: WorkoutDay? = nil, date: Date = .now, notes: String? = nil) {
        self.program = program
        self.day = day
        self.date = date
        self.notes = notes
    }
}


