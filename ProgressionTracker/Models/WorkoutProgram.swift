import Foundation
import SwiftData

// Represents a user's workout program (e.g., "Push Pull Legs").
// Relationships:
// - One-to-many with WorkoutDay via `days`
// - One-to-many with WorkoutSession via `sessions`
@Model
final class WorkoutProgram {
    var name: String
    var createdDate: Date

    // Child workout days that belong to this program
    // Inverse defined in `WorkoutDay.program`
    var days: [WorkoutDay] = []

    // Logged workout sessions associated with this program
    // Inverse defined in `WorkoutSession.program`
    var sessions: [WorkoutSession] = []
    
    // Tracks which workout day was completed last in the rotation
    // nil = no workouts completed yet
    // Value represents the orderIndex of the last completed day
    var lastCompletedDayIndex: Int?
    
    init(name: String, createdDate: Date = .now) {
        self.name = name
        self.createdDate = createdDate
    }
    
    // MARK: - Rotation Logic
    
    /// Returns the next workout day in the rotation cycle
    /// - Returns: The next WorkoutDay to perform, or nil if no days exist
    var nextWorkoutDay: WorkoutDay? {
        guard !days.isEmpty else { return nil }
        
        // Sort days by orderIndex to ensure proper rotation
        let sortedDays = days.sorted { $0.orderIndex < $1.orderIndex }
        
        if let lastCompleted = lastCompletedDayIndex {
            // Find the next day in sequence
            let nextIndex = lastCompleted + 1
            
            // If we've completed the last day, wrap back to the first day
            if nextIndex >= sortedDays.count {
                return sortedDays.first
            } else {
                return sortedDays.first { $0.orderIndex == nextIndex }
            }
        } else {
            // No workouts completed yet, start with the first day
            return sortedDays.first
        }
    }
    
    /// Marks a workout day as completed and updates the rotation tracking
    /// - Parameter day: The WorkoutDay that was completed
    func markDayCompleted(_ day: WorkoutDay) {
        lastCompletedDayIndex = day.orderIndex
    }
    
    /// Advances to the next day in rotation without logging a workout
    /// Useful for skipping days or manual rotation management
    func skipToNextDay() {
        guard !days.isEmpty else { return }
        
        let sortedDays = days.sorted { $0.orderIndex < $1.orderIndex }
        
        if let lastCompleted = lastCompletedDayIndex {
            // Move to next day in sequence
            let nextIndex = lastCompleted + 1
            
            // Wrap around if we've reached the end
            if nextIndex >= sortedDays.count {
                lastCompletedDayIndex = sortedDays.first?.orderIndex
            } else {
                lastCompletedDayIndex = nextIndex
            }
        } else {
            // No previous completion, start with first day
            lastCompletedDayIndex = sortedDays.first?.orderIndex
        }
    }
}


