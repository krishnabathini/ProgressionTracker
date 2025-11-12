import Foundation
import UserNotifications

/// Responsible for scheduling local notifications that help users preserve their workout streaks.
final class StreakNotificationManager {
    static let shared = StreakNotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    /// Requests permission to send local notifications.
    func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("❌ Notification authorization error: \(error.localizedDescription)")
                return
            }
            
            if success {
                print("🔔 Notification permissions granted.")
            } else {
                print("⚠️ Notification permissions denied by user.")
            }
        }
    }
    
    /// Schedules reminders that help the user maintain their streak.
    /// - Parameters:
    ///   - streak: The current streak count.
    ///   - lastWorkoutDate: The date of the most recent completed workout.
    func scheduleStreakNotifications(for streak: Int, lastWorkoutDate: Date?) {
        // Remove previously scheduled streak notifications so we don't stack duplicates.
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            NotificationIdentifier.dayBeforeReminder.rawValue,
            NotificationIdentifier.streakEndingReminder.rawValue
        ])
        
        guard let lastWorkoutDate = lastWorkoutDate else {
            print("ℹ️ No last workout date available. Skipping streak notifications.")
            return
        }
        
        // If there's no streak yet, skip scheduling.
        guard streak > 0 else {
            print("ℹ️ Current streak is zero. Skipping streak notifications.")
            return
        }
        
        let calendar = Calendar.current
        let startOfLastWorkout = calendar.startOfDay(for: lastWorkoutDate)
        
        // The user must work out within 3 days to maintain their streak (based on streak logic).
        guard
            let streakDeadlineDay = calendar.date(byAdding: .day, value: 3, to: startOfLastWorkout),
            let dayBeforeDeadline = calendar.date(byAdding: .day, value: -1, to: streakDeadlineDay)
        else {
            print("⚠️ Unable to compute notification dates.")
            return
        }
        
        // Schedule the day-before reminder (6 PM).
        if let dayBeforeTrigger = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayBeforeDeadline),
           dayBeforeTrigger > Date() {
            let request = createNotificationRequest(
                identifier: .dayBeforeReminder,
                title: "Streak Preservation Alert",
                body: "Rest day today? Make sure to work out tomorrow to keep your \(streak)-day streak alive!",
                triggerDate: dayBeforeTrigger
            )
            notificationCenter.add(request)
        }
        
        // Schedule the streak-ending reminder (6 PM on deadline day).
        if let deadlineTrigger = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: streakDeadlineDay),
           deadlineTrigger > Date() {
            let request = createNotificationRequest(
                identifier: .streakEndingReminder,
                title: "Streak Ending Today! 🚨",
                body: "Work out today or your \(streak)-day streak will come to an end. You've got this! 💪",
                triggerDate: deadlineTrigger
            )
            notificationCenter.add(request)
        }
    }
    
    // MARK: - Helpers
    
    private func createNotificationRequest(
        identifier: NotificationIdentifier,
        title: String,
        body: String,
        triggerDate: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        
        return UNNotificationRequest(
            identifier: identifier.rawValue,
            content: content,
            trigger: trigger
        )
    }
    
    private enum NotificationIdentifier: String {
        case dayBeforeReminder = "streakPreservationReminder"
        case streakEndingReminder = "streakEndingReminder"
    }
}

