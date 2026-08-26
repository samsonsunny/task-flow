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
    private(set) var scheduledTask: TaskItem?
    private(set) var listSections: [ListSection] = []
    private(set) var lastAddedTaskID: PersistentIdentifier?

    private(set) var allTasks: [TaskItem] = []
    private(set) var allLists: [ReminderList] = []
    private var displayTasks: [TaskItem] = []

    // MARK: - Collapse State

    var collapsedTasks: Set<String> = []
    private var manuallyExpanded: Set<String> = []

    func toggleTaskCollapsed(_ taskId: String) {
        if collapsedTasks.contains(taskId) {
            collapsedTasks.remove(taskId)
            manuallyExpanded.insert(taskId)
        } else {
            collapsedTasks.insert(taskId)
            manuallyExpanded.remove(taskId)
        }
        recompute()
    }

    private func collapseAllParentsWithSubtasks() {
        let parents = tasks.filter { !$0.subtasks.isEmpty }
        for task in parents {
            if let taskId = task.taskId, !manuallyExpanded.contains(taskId) {
                collapsedTasks.insert(taskId)
            }
        }
    }

    // MARK: - Init

    init(modelContext: ModelContext, listID: ReminderList.ID) {
        self.modelContext = modelContext
        self.listID = listID
    }

    // MARK: - Refresh / Update

    func refreshNow() {
        now = Date()
        recompute()
    }

    func update(tasks: [TaskItem], lists: [ReminderList], allTasks: [TaskItem], now: Date = Date()) {
        self.displayTasks = tasks
        self.allTasks = allTasks
        self.allLists = lists
        self.now = now
        recompute()
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
                        self.recompute()
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
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    private func recompute() {
        list = allLists.first { $0.persistentModelID == listID }
        tasks = computeTasks().sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        collapseAllParentsWithSubtasks()
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

    func commitQuickCapture(text: String, notes: String = "", in listID: ReminderList.ID?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let list = allLists.first(where: { $0.persistentModelID == (listID ?? self.listID) }) else { return }
        let task = TaskItem(taskTitle: trimmed, dueDate: nil)
        task.createdAt = Date()
        task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task.reminderList = list
        modelContext.insert(task)
        assignSortOrder(for: task, in: list)
        try? modelContext.save()
        lastAddedTaskID = task.persistentModelID
        recompute()
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
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    // MARK: - List Move (2.3)

    func moveTask(_ task: TaskItem, to list: ReminderList) {
        task.reminderList = list
        task.parentTask = nil
        assignSortOrder(for: task, in: list)
        try? modelContext.save()
        recompute()
    }

    func assignSortOrder(for task: TaskItem, in list: ReminderList) {
        let listTasks = allTasks.filter {
            $0.reminderList?.persistentModelID == list.persistentModelID &&
            $0.persistentModelID != task.persistentModelID
        }
        task.sortOrder = nextSortOrder(for: listTasks)
    }

    // MARK: - Drag-Drop Reorder (2.4)

    func moveTasks(fromOffsets: IndexSet, toOffset: Int) {
        var mutableTasks = tasks
        let sortedFrom = fromOffsets.sorted()

        let moved = Array(sortedFrom.reversed().map { mutableTasks.remove(at: $0) }.reversed())

        var adjustedOffset = toOffset
        for idx in sortedFrom where idx < toOffset {
            adjustedOffset -= 1
        }
        let insertAt = min(adjustedOffset, mutableTasks.count)

        mutableTasks.insert(contentsOf: moved, at: insertAt)

        recalculateSortOrders(for: mutableTasks)

        try? modelContext.save()
        recompute()
    }

    func moveSubtasks(fromOffsets: IndexSet, toOffset: Int, of parent: TaskItem) {
        var siblings = parent.subtasks.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        let sortedFrom = fromOffsets.sorted()

        let moved = Array(sortedFrom.reversed().map { siblings.remove(at: $0) }.reversed())

        var adjustedOffset = toOffset
        for idx in sortedFrom where idx < toOffset {
            adjustedOffset -= 1
        }
        let insertAt = min(adjustedOffset, siblings.count)

        siblings.insert(contentsOf: moved, at: insertAt)

        recalculateSortOrders(for: siblings)

        try? modelContext.save()
        recompute()
    }

    // MARK: - Move to Top / Bottom

    func siblings(of task: TaskItem) -> [TaskItem] {
        if let parent = task.parentTask {
            return tasks.filter {
                $0.parentTask?.persistentModelID == parent.persistentModelID &&
                $0.persistentModelID != task.persistentModelID
            }
        }
        return rootTasks.filter { $0.persistentModelID != task.persistentModelID }
    }

    func moveToTop(task: TaskItem) {
        let sibs = siblings(of: task)
        var sorted = sibs.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        sorted.insert(task, at: 0)
        recalculateSortOrders(for: sorted)
        try? modelContext.save()
        recompute()
    }

    func moveToBottom(task: TaskItem) {
        let sibs = siblings(of: task)
        var sorted = sibs.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        sorted.append(task)
        recalculateSortOrders(for: sorted)
        try? modelContext.save()
        recompute()
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
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToToday(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = Calendar.current.startOfDay(for: now)
        try? modelContext.save()
        recompute()
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
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToNone(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = nil
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToNextWeek(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = ReminderSegmentViewModel.nextMonday(from: now)
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToThisWeekend(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = ReminderSegmentViewModel.nextSaturday(from: now)
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    // MARK: - Bulk Operations

    func bulkRescheduleToToday(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToReschedule = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = Calendar.current.startOfDay(for: now)
        }
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToTomorrow(_ taskIDs: Set<PersistentIdentifier>) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        let tasksToReschedule = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = tomorrow
        }
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToNextWeek(_ taskIDs: Set<PersistentIdentifier>) {
        let nextMon = ReminderSegmentViewModel.nextMonday(from: now)
        let tasksToReschedule = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = nextMon
        }
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToThisWeekend(_ taskIDs: Set<PersistentIdentifier>) {
        let saturday = ReminderSegmentViewModel.nextSaturday(from: now)
        let tasksToReschedule = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = saturday
        }
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToDate(_ taskIDs: Set<PersistentIdentifier>, dueDate: Date?, hasTime: Bool) {
        let tasksToReschedule = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
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
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToNone(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToReschedule = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = nil
        }
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkMoveToList(_ taskIDs: Set<PersistentIdentifier>, list: ReminderList) {
        let tasksToMove = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToMove {
            task.reminderList = list
            task.parentTask = nil
            assignSortOrder(for: task, in: list)
        }
        try? modelContext.save()
        recompute()
    }

    func bulkToggleCompletion(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToToggle = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToToggle {
            let next = !(task.isCompleted ?? false)
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
            if next, let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
        }
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkDelete(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToDelete = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToDelete {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.deleteDescendants()
            modelContext.delete(task)
        }
        try? modelContext.save()
        recompute()
        BadgeService.update(modelContext: modelContext)
    }

    func bulkSetPriority(_ taskIDs: Set<PersistentIdentifier>, priority: ReminderPriority) {
        let tasksToUpdate = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToUpdate {
            task.priorityRawValue = priority.rawValue
        }
        try? modelContext.save()
        recompute()
    }
}
