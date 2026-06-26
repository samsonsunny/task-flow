import SwiftUI
import SwiftData

@MainActor
@Observable
final class CompletedViewModel {
    private let modelContext: ModelContext

    private(set) var recentCompletedTasks: [TaskItem] = []
    private(set) var groupedTasks: [(String, [TaskItem])] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func update(tasks: [TaskItem], now: Date = Date()) {
        self.recentCompletedTasks = Self.computeRecentTasks(tasks, now: now)
        self.groupedTasks = Self.computeGroupedTasks(self.recentCompletedTasks, now: now)
    }

    static func computeRecentTasks(_ tasks: [TaskItem], now: Date = Date()) -> [TaskItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        return tasks.filter { task in
            guard task.isCompleted == true else { return false }
            let completionDate = task.completionDate ?? task.createdAt ?? now
            return completionDate >= cutoff
        }
    }

    static func computeGroupedTasks(_ tasks: [TaskItem], now: Date = Date()) -> [(String, [TaskItem])] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart)!

        var today: [TaskItem] = []
        var yesterday: [TaskItem] = []
        var thisWeek: [TaskItem] = []
        var earlier: [TaskItem] = []

        for task in tasks {
            let date = task.completionDate ?? task.createdAt ?? now
            let dayStart = calendar.startOfDay(for: date)

            if calendar.isDate(dayStart, inSameDayAs: todayStart) {
                today.append(task)
            } else if calendar.isDate(dayStart, inSameDayAs: yesterdayStart) {
                yesterday.append(task)
            } else if dayStart >= weekStart {
                thisWeek.append(task)
            } else {
                earlier.append(task)
            }
        }

        var result: [(String, [TaskItem])] = []
        if !today.isEmpty { result.append(("Today", today)) }
        if !yesterday.isEmpty { result.append(("Yesterday", yesterday)) }
        if !thisWeek.isEmpty { result.append(("This Week", thisWeek)) }
        if !earlier.isEmpty { result.append(("Earlier", earlier)) }
        return result
    }

    func uncomplete(_ task: TaskItem) {
        task.isCompleted = false
        task.completionDate = nil
        if task.safeHasTime {
            NotificationService.shared.schedule(for: task)
        }
    }

    func delete(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        modelContext.delete(task)
        try? modelContext.save()
    }

    static func destinationLabel(for task: TaskItem, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)

        guard let dueDate = task.dueDate else {
            return "Will reappear in Later"
        }

        let dueStart = calendar.startOfDay(for: dueDate)
        if dueStart < todayStart {
            return "Was overdue"
        } else if calendar.isDate(dueStart, inSameDayAs: todayStart) {
            return "Will reappear in Today"
        } else if calendar.isDateInTomorrow(dueStart) {
            return "Will reappear in Tomorrow"
        } else {
            return "Will reappear in Upcoming"
        }
    }
}
