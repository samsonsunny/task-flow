import UserNotifications
import SwiftData
import Foundation

enum DailyReminderKeys {
    static let enabled = "dailyReminderEnabled"
    static let hour = "dailyReminderHour"
    static let minute = "dailyReminderMinute"
}

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private init() {}

    var isAuthorized: Bool {
        get async {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = try? await center.requestAuthorization(options: [.alert, .sound])
            return granted == true
        case .authorized:
            return true
        default:
            return false
        }
    }

    func schedule(for task: TaskItem) {
        guard
            let taskId = task.taskId,
            let dueDate = task.dueDate,
            dueDate > Date(),
            let title = task.taskTitle,
            !title.isEmpty,
            task.safeHasTime
        else { return }

        // Cancel existing notification for this task first
        cancel(taskId: taskId)

        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: taskId,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancel(taskId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [taskId])
        center.removeDeliveredNotifications(withIdentifiers: [taskId])
    }

    private let dailyReminderId = "daily-morning-reminder"

    func scheduleDailyReminder(hour: Int, minute: Int) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "☀️ Good morning — your day is waiting"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: dailyReminderId,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
        center.removeDeliveredNotifications(withIdentifiers: [dailyReminderId])
    }

    func reschedulePendingOnLaunch(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.dueDate != nil && $0.isCompleted != true }
        )

        guard let allTasks = try? modelContext.fetch(descriptor) else { return }
        let now = Date()
        let futureTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate > now && task.safeHasTime
        }

        Task {
            let pending = await center.pendingNotificationRequests()
            let pendingIds = Set(pending.map { $0.identifier })

            for task in futureTasks {
                guard let taskId = task.taskId, !pendingIds.contains(taskId) else { continue }
                schedule(for: task)
            }

            if defaults.bool(forKey: DailyReminderKeys.enabled) {
                guard !pendingIds.contains(dailyReminderId) else { return }
                let hour = defaults.integer(forKey: DailyReminderKeys.hour)
                let minute = defaults.integer(forKey: DailyReminderKeys.minute)
                scheduleDailyReminder(hour: hour, minute: minute)
            }
        }
    }
}
