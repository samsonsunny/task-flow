import Foundation
import SwiftData

enum TaskListLogic {
    static func taskKey(for task: TaskItem) -> String {
        if let taskId = task.taskId, !taskId.isEmpty {
            return taskId
        }
        return String(describing: task.persistentModelID)
    }

    static func filteredTasks(_ tasks: [TaskItem], for bucket: TaskBucket, now: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart)
        return tasks.filter { task in
            guard let dueDate = task.dueDate else {
                return bucket == .someday
            }
            switch bucket {
            case .today:
                return calendar.isDateInToday(dueDate)
            case .tomorrow:
                return calendar.isDateInTomorrow(dueDate)
            case .upcoming:
                let dueStart = calendar.startOfDay(for: dueDate)
                return dueStart > tomorrowStart
            case .someday:
                return false
            }
        }
    }

    static func sortUpcomingTasks(_ items: [TaskItem], calendar: Calendar = .current) -> [TaskItem] {
        items.sorted { lhs, rhs in
            let lhsDue = calendar.startOfDay(for: lhs.dueDate ?? .distantFuture)
            let rhsDue = calendar.startOfDay(for: rhs.dueDate ?? .distantFuture)
            if lhsDue != rhsDue {
                return lhsDue < rhsDue
            }
            let lhsCreatedAt = lhs.createdAt ?? .distantPast
            let rhsCreatedAt = rhs.createdAt ?? .distantPast
            if lhsCreatedAt != rhsCreatedAt {
                return lhsCreatedAt > rhsCreatedAt
            }
            return taskKey(for: lhs) < taskKey(for: rhs)
        }
    }
}
