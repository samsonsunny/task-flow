import UserNotifications
import SwiftData
import Foundation

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

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
            !title.isEmpty
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
    }

    func reschedulePendingOnLaunch(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.dueDate != nil }
        )

        guard let allTasks = try? modelContext.fetch(descriptor) else { return }
        let now = Date()
        let futureTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate > now
        }

        Task {
            let pending = await center.pendingNotificationRequests()
            let pendingIds = Set(pending.map { $0.identifier })

            for task in futureTasks {
                guard let taskId = task.taskId, !pendingIds.contains(taskId) else { continue }
                schedule(for: task)
            }
        }
    }
}
