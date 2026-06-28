import SwiftUI
import SwiftData

@MainActor
@Observable
final class CompletedViewModel {
    private let modelContext: ModelContext
    private let appState: AppState
    private var allTasks: [TaskItem] = []

    private(set) var recentCompletedTasks: [TaskItem] = []
    private(set) var groupedTasks: [(String, [TaskItem])] = []

    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
    }

    func update(tasks: [TaskItem], now: Date = Date()) {
        self.allTasks = tasks
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

        let sortDescending: ([TaskItem]) -> [TaskItem] = { tasks in
            tasks.sorted { lhs, rhs in
                let lDate = lhs.completionDate ?? lhs.createdAt ?? now
                let rDate = rhs.completionDate ?? rhs.createdAt ?? now
                return lDate > rDate
            }
        }

        var result: [(String, [TaskItem])] = []
        if !today.isEmpty { result.append(("Today", sortDescending(today))) }
        if !yesterday.isEmpty { result.append(("Yesterday", sortDescending(yesterday))) }
        if !thisWeek.isEmpty { result.append(("This Week", sortDescending(thisWeek))) }
        if !earlier.isEmpty { result.append(("Earlier", sortDescending(earlier))) }
        return result
    }

    static func completionTimeLabel(for task: TaskItem, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let date = task.completionDate ?? task.createdAt ?? now
        if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
            return Self.timeFormatter.string(from: date)
        }
        return Self.dateFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()

    func uncomplete(_ task: TaskItem) {
        task.isCompleted = false
        task.completionDate = nil
        if task.safeHasTime {
            NotificationService.shared.schedule(for: task)
        }
        try? modelContext.save()
        appState.notifyMutation()
        update(tasks: allTasks)
    }

    private(set) var justUncompleted: Set<String> = []

    func beginUncomplete(_ task: TaskItem) {
        guard let id = task.taskId else {
            uncomplete(task)
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        justUncompleted.insert(id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }
            self.justUncompleted.remove(id)
            self.uncomplete(task)
        }
    }

    func delete(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        modelContext.delete(task)
        try? modelContext.save()
        appState.notifyMutation()
        allTasks.removeAll { $0.persistentModelID == task.persistentModelID }
        update(tasks: allTasks)
    }
}
