import Foundation
import SwiftData

// Represents a specific day within a program (e.g., "Push", "Pull", "Legs").
// Relationships:
// - Many-to-one to WorkoutProgram via `program`
// - One-to-many with Exercise via `exercises`
@Model
final class WorkoutDay {
    // Back-reference to the owning program
    var program: WorkoutProgram?

    var name: String
    var orderIndex: Int

    // Exercises scheduled for this day
    // Inverse defined in `Exercise.day`
    var exercises: [Exercise] = []

    init(program: WorkoutProgram? = nil, name: String, orderIndex: Int) {
        self.program = program
        self.name = name
        self.orderIndex = orderIndex
    }
}


