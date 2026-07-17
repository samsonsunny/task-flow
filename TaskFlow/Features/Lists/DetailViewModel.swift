import SwiftUI
import SwiftData

@MainActor
@Observable
final class ListDetailViewModel {
    private let modelContext: ModelContext
    let listID: ReminderList.ID

    private(set) var list: ReminderList?
    private(set) var tasks: [TaskItem] = []
    private(set) var rootTasks: [TaskItem] = []
    private(set) var flatNodes: [FlatTaskNode] = []

    private(set) var justCompleted: Set<String> = []
    private(set) var now: Date = Date()
    var draggedTaskId: String?
    private(set) var scheduledTask: TaskItem?
    private(set) var listSections: [ListSection] = []

    private(set) var allTasks: [TaskItem] = []
    private(set) var allLists: [ReminderList] = []
    private var displayTasks: [TaskItem] = []
    private var cachedCollapsedTasks: Set<PersistentIdentifier> = []

    init(modelContext: ModelContext, listID: ReminderList.ID) {
        self.modelContext = modelContext
        self.listID = listID
    }

    func refreshNow() {
        now = Date()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }

    func update(tasks: [TaskItem], lists: [ReminderList], allTasks: [TaskItem], now: Date = Date(), collapsedTasks: Set<PersistentIdentifier> = []) {
        self.displayTasks = tasks
        self.allTasks = allTasks
        self.allLists = lists
        self.now = now
        self.cachedCollapsedTasks = collapsedTasks
        recompute(collapsedTasks: collapsedTasks)
    }

    func toggleCompletion(for task: TaskItem) {
        let next = !(task.isCompleted ?? false)
        if next {
            if let id = task.taskId {
                justCompleted.insert(id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak task] in
                    guard let self, let task, task.isCompleted == true else { return }
                    _ = withAnimation {
                        self.justCompleted.remove(id)
                        self.recompute(collapsedTasks: self.cachedCollapsedTasks)
                        BadgeService.update(modelContext: self.modelContext)
                    }
                }
            }
        } else if let id = task.taskId {
            justCompleted.remove(id)
        }
        task.isCompleted = next
        task.completionDate = next ? Date() : nil
        if next, let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    private func recompute(collapsedTasks: Set<PersistentIdentifier>) {
        list = allLists.first { $0.persistentModelID == listID }
        tasks = computeTasks().sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        let taskIDs = Set(tasks.map(\.persistentModelID))
        rootTasks = tasks.filter {
            guard let parent = $0.parentTask else { return true }
            return !taskIDs.contains(parent.persistentModelID)
        }
        flatNodes = TaskTreeFlattener.flatten(roots: rootTasks, collapsed: collapsedTasks)
        listSections = buildListSections(from: allLists, excluding: listID)
    }

    private func computeTasks() -> [TaskItem] {
        displayTasks.filter {
            guard $0.reminderList?.persistentModelID == listID else { return false }
            if $0.isCompleted == true {
                return justCompleted.contains($0.taskId ?? "")
            }
            return true
        }
    }

    // MARK: - Quick Capture (2.1 / 2.8)

    func commitQuickCapture(text: String, in listID: ReminderList.ID?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let list = allLists.first(where: { $0.persistentModelID == (listID ?? self.listID) }) else { return }
        let task = TaskItem(taskTitle: trimmed, dueDate: nil)
        task.createdAt = Date()
        task.reminderList = list
        modelContext.insert(task)
        assignSortOrder(for: task, in: list)
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func openQuickCaptureEditor(text: String, listID: ReminderList.ID?) -> (String, ReminderList.ID) {
        (text.trimmingCharacters(in: .whitespacesAndNewlines), listID ?? self.listID)
    }

    // MARK: - Delete (2.2)

    func delete(task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.deleteDescendants()
        modelContext.delete(task)
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    // MARK: - List Move (2.3)

    func moveTask(_ task: TaskItem, to list: ReminderList) {
        task.reminderList = list
        task.parentTask = nil
        assignSortOrder(for: task, in: list)
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }

    func assignSortOrder(for task: TaskItem, in list: ReminderList) {
        let listTasks = allTasks.filter {
            $0.reminderList?.persistentModelID == list.persistentModelID &&
            $0.persistentModelID != task.persistentModelID
        }
        let lastOrder = listTasks.compactMap { $0.sortOrder }.sorted().last
        task.sortOrder = midpoint(between: lastOrder, and: nil)
    }

    // MARK: - Drag-Drop Reorder (2.4)

    func moveTasks(fromOffsets: IndexSet, toOffset: Int) {
        var mutableTasks = tasks
        let sortedFrom = fromOffsets.sorted()

        let moved = Array(sortedFrom.reversed().map { mutableTasks.remove(at: $0) }.reversed())
        let insertAt = min(toOffset, mutableTasks.count)

        mutableTasks.insert(contentsOf: moved, at: insertAt)

        var lower = insertAt > 0 ? mutableTasks[insertAt - 1].sortOrder : nil
        for i in insertAt..<(insertAt + moved.count) {
            let upper = (i + 1) < mutableTasks.count ? mutableTasks[i + 1].sortOrder : nil

            if let existing = moved[i - insertAt].sortOrder, isBetween(existing, lower: lower, upper: upper) {
                mutableTasks[i].sortOrder = existing
            } else if let newOrder = midpoint(between: lower, and: upper) {
                mutableTasks[i].sortOrder = newOrder
            } else {
                if let upperStr = upper {
                    let widened = widen(upperStr)
                    mutableTasks[i + 1].sortOrder = widened
                    mutableTasks[i].sortOrder = midpoint(between: lower, and: widened) ?? (lower ?? "m") + "zz"
                } else {
                    let widened = widen(lower ?? "m")
                    mutableTasks[i].sortOrder = midpoint(between: widened, and: nil) ?? widened + "z"
                }
            }

            lower = mutableTasks[i].sortOrder
        }

        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }

    // MARK: - Drag-Drop Nesting (2.5)

    func handleDrop(target: TaskItem, location: CGPoint) {
        guard let draggedTaskId,
              let draggedTask = allTasks.first(where: { $0.taskId == draggedTaskId }),
              draggedTask.persistentModelID != target.persistentModelID else { return }

        guard !isDescendant(target, of: draggedTask) else { return }

        let threshold: CGFloat = 22
        if location.y < threshold {
            draggedTask.parentTask = target.parentTask
            let siblings: [TaskItem]
            if let parent = target.parentTask {
                siblings = Array(parent.subtasks)
            } else {
                siblings = rootTasks.filter { $0.persistentModelID != draggedTask.persistentModelID }
            }
            let sorted = siblings.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
            if let idx = sorted.firstIndex(where: { $0.persistentModelID == target.persistentModelID }) {
                let prev = idx > 0 ? sorted[idx - 1].sortOrder : nil
                draggedTask.sortOrder = midpoint(between: prev, and: target.sortOrder)
            }
        } else {
            draggedTask.parentTask = target
            let subbies = target.subtasks.filter { $0.persistentModelID != draggedTask.persistentModelID }
                .sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
            let lastOrder = subbies.last?.sortOrder ?? target.sortOrder
            draggedTask.sortOrder = midpoint(between: lastOrder, and: nil)
        }
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }

    func moveTaskToRoot() {
        guard let draggedTaskId,
              let task = allTasks.first(where: { $0.taskId == draggedTaskId }) else { return }
        task.parentTask = nil
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }

    func isDescendant(_ task: TaskItem, of potentialParent: TaskItem) -> Bool {
        var current = task
        while let parent = current.parentTask {
            if parent.persistentModelID == potentialParent.persistentModelID {
                return true
            }
            current = parent
        }
        return false
    }

    // MARK: - Scheduling (2.6)

    func presentScheduleSheet(for task: TaskItem) {
        scheduledTask = task
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
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToToday(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = Calendar.current.startOfDay(for: now)
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToTomorrow(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        task.dueDate = calendar.date(byAdding: .day, value: 1, to: todayStart)
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToLater(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = nil
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    // MARK: - Helpers (2.7)

    func canMoveToToday(_ task: TaskItem) -> Bool {
        guard let dueDate = task.dueDate else { return true }
        return !Calendar.current.isDateInToday(dueDate)
    }

    func canMoveToTomorrow(_ task: TaskItem) -> Bool {
        guard let dueDate = task.dueDate else { return true }
        return !Calendar.current.isDateInTomorrow(dueDate)
    }

}
