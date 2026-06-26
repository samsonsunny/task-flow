import SwiftUI
import SwiftData

@MainActor
@Observable
final class ReminderSegmentViewModel {
    private let modelContext: ModelContext
    let segment: ReminderSegment
    let overdueTasks: [TaskItem]

    private(set) var now: Date = Date()
    private(set) var showOverdue: Bool = true
    private(set) var justCompleted: Set<String> = []

    private(set) var filteredTasks: [TaskItem] = []
    private(set) var groupedSections: [TaskUIModel.DatedSection] = []
    private(set) var upcomingGroups: [TaskUIModel.UpcomingGroup] = []
    private(set) var sortedFlatTasks: [TaskItem] = []

    private var lists: [ReminderList] = []

    init(modelContext: ModelContext, segment: ReminderSegment, overdueTasks: [TaskItem] = []) {
        self.modelContext = modelContext
        self.segment = segment
        self.overdueTasks = overdueTasks
    }

    func refreshNow() {
        now = Date()
    }

    func update(tasks: [TaskItem], lists: [ReminderList], now: Date = Date()) {
        self.now = now
        self.lists = lists
        self.filteredTasks = ReminderSegmentLogic.filteredTasks(tasks, for: segment, now: now)
        self.groupedSections = ReminderSegmentLogic.datedSections(from: tasks, for: segment, now: now)
        self.upcomingGroups = ReminderSegmentLogic.upcomingGroups(from: tasks, now: now)
        let sorted = ReminderSegmentLogic.sortedTasks(self.filteredTasks, for: segment)
        let recent = tasks.filter { justCompleted.contains($0.taskId ?? "") }
        self.sortedFlatTasks = sorted + recent
    }

    var contextualDate: Date? {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        switch segment {
        case .today: return todayStart
        case .tomorrow: return calendar.date(byAdding: .day, value: 1, to: todayStart)
        default: return nil
        }
    }

    func captureDateHint(activeCaptureDate: Date?) -> String? {
        let date: Date?
        if segment == .upcoming {
            date = activeCaptureDate
        } else {
            date = contextualDate
        }
        guard let date else { return nil }
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        return TaskUIModel.compactDayTitle(for: date)
    }

    func resolvedQuickCaptureList() -> ReminderList {
        let defaultName = ReminderDefaults.defaultListName
        let descriptor = FetchDescriptor<ReminderList>(
            predicate: #Predicate { $0.name == defaultName }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let list = ReminderList(name: ReminderDefaults.defaultListName)
        modelContext.insert(list)
        return list
    }

    func shouldShowDueDate(for segment: ReminderSegment) -> Bool {
        switch segment {
        case .today, .tomorrow, .later: return false
        case .upcoming, .overdue: return true
        }
    }

    var otherLists: [ReminderList] {
        lists
    }

    // MARK: - Mutations

    func toggleCompletion(for task: TaskItem) {
        let next = !(task.isCompleted ?? false)
        if next {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if let id = task.taskId {
                justCompleted.insert(id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self, weak task] in
                    guard let self, let task, task.isCompleted == true else { return }
                    self.justCompleted.remove(id)
                }
            }
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
            if next, let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
        }
    }

    func commitQuickCapture(text: String, captureDate: Date?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let dueDate: Date?
        if segment == .upcoming {
            guard let captureDate else { return }
            dueDate = captureDate
        } else {
            dueDate = contextualDate
        }

        let task = TaskItem(
            taskTitle: trimmed,
            dueDate: dueDate
        )
        task.createdAt = Date()
        task.reminderList = resolvedQuickCaptureList()
        modelContext.insert(task)
    }

    func openQuickCaptureEditor(text: String, captureDate: Date?) -> (initialDate: Date?, initialTitle: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let initialDate: Date?
        if segment == .upcoming {
            initialDate = captureDate
        } else {
            initialDate = contextualDate
        }
        return (initialDate, trimmed)
    }

    func delete(task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        modelContext.delete(task)
        try? modelContext.save()
    }

    func moveTask(_ task: TaskItem, to list: ReminderList) {
        task.reminderList = list
        assignSortOrder(for: task, in: list)
        try? modelContext.save()
    }

    private func assignSortOrder(for task: TaskItem, in list: ReminderList) {
        let descriptor = FetchDescriptor<TaskItem>()
        guard let allTasks = try? modelContext.fetch(descriptor) else { return }
        let listTasks = allTasks.filter {
            $0.reminderList?.persistentModelID == list.persistentModelID &&
            $0.persistentModelID != task.persistentModelID
        }
        let lastOrder = listTasks.compactMap { $0.sortOrder }.sorted().last
        task.sortOrder = midpoint(between: lastOrder, and: nil)
    }

    func scheduleTask(_ task: TaskItem, dueDate: Date?, hasTime: Bool) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        if let date = dueDate {
            if hasTime {
                task.dueDate = date
                task.hasTime = true
                NotificationService.shared.schedule(for: task)
            } else {
                task.dueDate = Calendar.current.startOfDay(for: date)
                task.hasTime = false
            }
        } else {
            task.dueDate = nil
        }
    }

    func rescheduleToToday(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = Calendar.current.startOfDay(for: now)
    }

    func rescheduleToTomorrow(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        task.dueDate = calendar.date(byAdding: .day, value: 1, to: todayStart)
    }

    func rescheduleToLater(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = nil
    }

    func canMoveToToday(_ task: TaskItem) -> Bool {
        guard let dueDate = task.dueDate else { return true }
        return !Calendar.current.isDateInToday(dueDate)
    }

    func canMoveToTomorrow(_ task: TaskItem) -> Bool {
        guard let dueDate = task.dueDate else { return true }
        return !Calendar.current.isDateInTomorrow(dueDate)
    }
}
