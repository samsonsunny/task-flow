import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let dailyReviewId = "daily.review.reminder"
    private let defaultReminderHour = 9
    private let defaultReminderMinute = 0
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    func scheduleDailyReview() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReviewId])
        
        let content = UNMutableNotificationContent()
        content.title = "Daily review"
        content.body = "Take a minute to review today's tasks."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = defaultReminderHour
        dateComponents.minute = defaultReminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReviewId, content: content, trigger: trigger)
        center.add(request)
    }
    
    func cancelDailyReview() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReviewId])
    }
    
    func scheduleReminder(for task: TaskItem) {
        let identifier = reminderIdentifier(for: task)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        guard let date = nextReminderDate(for: task) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = task.safeTitle
        content.body = "Task reminder"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
    
    func cancelReminder(for task: TaskItem) {
        let identifier = reminderIdentifier(for: task)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    private func nextReminderDate(for task: TaskItem) -> Date? {
        if task.safeIsCompleted {
            return nil
        }
        
        let now = Date()
        if let remindAt = task.remindAt, remindAt > now {
            return remindAt
        }
        
        guard let dueDate = task.dueDate else {
            return nil
        }
        
        let calendar = Calendar.current
        let scheduled = calendar.date(
            bySettingHour: defaultReminderHour,
            minute: defaultReminderMinute,
            second: 0,
            of: dueDate
        ) ?? dueDate
        
        return scheduled > now ? scheduled : nil
    }
    
    private func reminderIdentifier(for task: TaskItem) -> String {
        if task.taskId == nil {
            task.taskId = UUID().uuidString
        }
        return "task.reminder.\(task.taskId ?? UUID().uuidString)"
    }
}
