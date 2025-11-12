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

// MARK: - Streak Tracking Extension

extension WorkoutProgram {
    /// Calculates the current workout streak based on consecutive workout days
    /// A streak continues if workouts are within 2 days of each other
    /// A gap of 3 or more days breaks the streak
    var currentStreak: Int {
        print("🔍 Streak Calculation Diagnostic")
        
        let calendar = Calendar.current
        let sessions = self.sessions.sorted { $0.date < $1.date }
        
        // Log total number of sessions
        print("Total Sessions: \(sessions.count)")
        
        guard !sessions.isEmpty else {
            print("❌ No sessions found - returning streak 0")
            return 0
        }
        
        // Get unique workout dates (start of day)
        let uniqueWorkoutDates = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        
        // Log all unique workout dates
        print("Unique Workout Dates:")
        let sortedDates = uniqueWorkoutDates.sorted()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        sortedDates.forEach { date in
            print("  - \(formatter.string(from: date))")
        }
        
        guard !sortedDates.isEmpty else {
            print("❌ No workout dates found - returning streak 0")
            return 0
        }
        
        // Log last workout date and today
        let lastWorkoutDate = sortedDates.last!
        let today = calendar.startOfDay(for: Date())
        let daysSinceLastWorkout = calendar.dateComponents([.day], from: lastWorkoutDate, to: today).day ?? 0
        
        print("Last Workout Date: \(formatter.string(from: lastWorkoutDate))")
        print("Today's Date: \(formatter.string(from: today))")
        print("Days Since Last Workout: \(daysSinceLastWorkout)")
        
        // Check if streak is still active (hasn't expired)
        // A gap of 3 or more days breaks the streak
        if daysSinceLastWorkout >= 3 {
            print("❌ Streak expired - gap of \(daysSinceLastWorkout) days since last workout")
            return 0
        }
        
        // Calculate streak by iterating backwards from most recent workout
        var streak = 1
        var lastDate = lastWorkoutDate
        
        print("\n📊 Calculating streak backwards from most recent workout:")
        
        // Iterate backwards through dates
        for date in sortedDates.reversed().dropFirst() {
            let daysBetween = calendar.dateComponents([.day], from: date, to: lastDate).day ?? 0
            
            print("  Checking date: \(formatter.string(from: date))")
            print("    Days between workouts: \(daysBetween)")
            
            if daysBetween <= 3 {
                // If within 3 days (allowing up to 2 day gap), continue streak
                streak += 1
                lastDate = date
                print("    ✅ Streak continues: \(streak) days")
            } else {
                // More than 3 days gap breaks streak
                print("    ❌ Streak breaks - gap of \(daysBetween) days")
                break
            }
        }
        
        print("🏆 Final Streak: \(streak) days")
        return streak
    }
    
    /// Calculates the longest workout streak ever achieved in this program
    var longestStreak: Int {
        let calendar = Calendar.current
        
        // Get unique workout dates
        let uniqueDates = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        let sortedDates = uniqueDates.sorted()
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        var lastDate = sortedDates[0]
        
        // Iterate through all dates to find longest streak
        for date in sortedDates.dropFirst() {
            let daysBetween = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0
            
            if daysBetween <= 3 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
            
            lastDate = date
        }
        
        return maxStreak
    }
    
    /// Returns a warning message if the user needs to workout today to maintain their streak
    /// Shows when it's been 2 days since the last workout (last day to maintain streak)
    var streakWarningMessage: String? {
        let calendar = Calendar.current
        let sessions = self.sessions.sorted { $0.date < $1.date }
        
        guard !sessions.isEmpty else { return nil }
        
        let uniqueWorkoutDates = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        let sortedDates = uniqueWorkoutDates.sorted()
        
        guard let lastWorkoutDate = sortedDates.last else { return nil }
        
        // Check if today is the last day to maintain streak
        let today = calendar.startOfDay(for: Date())
        let daysSinceLastWorkout = calendar.dateComponents([.day], from: lastWorkoutDate, to: today).day ?? 0
        
        // If it's been 3 days since last workout, show warning
        if daysSinceLastWorkout == 3 {
            return "Workout today to keep your streak!"
        }
        
        return nil
    }
    
    /// Requests notification permissions and schedules reminders to preserve the current streak.
    func updateStreakNotifications() {
        StreakNotificationManager.shared.requestNotificationPermissions()
        
        let lastWorkoutDate = sessions.sorted { $0.date < $1.date }.last?.date
        StreakNotificationManager.shared.scheduleStreakNotifications(for: currentStreak, lastWorkoutDate: lastWorkoutDate)
    }
}


