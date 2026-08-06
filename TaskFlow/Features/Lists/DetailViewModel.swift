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
        flatNodes = TaskTreeFlattener.flatten(roots: rootTasks, collapsed: collapsedTasks, nestSubtasks: false)
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
        task.sortOrder = midpointOrWiden(between: lastOrder, and: nil)
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

        var previous: String? = insertAt > 0 ? mutableTasks[insertAt - 1].sortOrder : nil
        for i in insertAt..<(insertAt + moved.count) {
            let upper = (i + 1) < mutableTasks.count ? mutableTasks[i + 1].sortOrder : nil
            mutableTasks[i].sortOrder = midpointOrWiden(between: previous, and: upper)
            previous = mutableTasks[i].sortOrder
        }

        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        var sorted = sibs.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        sorted.insert(task, at: 0)
        var previous: String? = nil
        for t in sorted {
            t.sortOrder = midpointOrWiden(between: previous, and: nil)
            previous = t.sortOrder
        }
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }

    func moveToBottom(task: TaskItem) {
        let sibs = siblings(of: task)
        var sorted = sibs.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        sorted.append(task)
        var previous: String? = nil
        for t in sorted {
            t.sortOrder = midpointOrWiden(between: previous, and: nil)
            previous = t.sortOrder
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
            var sorted = siblings.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
            if let idx = sorted.firstIndex(where: { $0.persistentModelID == target.persistentModelID }) {
                sorted.insert(draggedTask, at: idx)
                var previous: String? = nil
                for t in sorted {
                    t.sortOrder = midpointOrWiden(between: previous, and: nil)
                    previous = t.sortOrder
                }
            }
        } else {
            draggedTask.parentTask = target
            var subbies = target.subtasks.filter { $0.persistentModelID != draggedTask.persistentModelID }
                .sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
            subbies.append(draggedTask)
            var previous: String? = nil
            for t in subbies {
                t.sortOrder = midpointOrWiden(between: previous, and: nil)
                previous = t.sortOrder
            }
        }
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }

    func moveTaskToRoot() {
        guard let draggedTaskId,
              let task = allTasks.first(where: { $0.taskId == draggedTaskId }) else { return }
        task.parentTask = nil
        var siblings = rootTasks.filter { $0.persistentModelID != task.persistentModelID }
            .sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        siblings.append(task)
        var previous: String? = nil
        for t in siblings {
            t.sortOrder = midpointOrWiden(between: previous, and: nil)
            previous = t.sortOrder
        }
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

    func rescheduleTaskToNone(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = nil
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToNextWeek(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = ReminderSegmentViewModel.nextMonday(from: now)
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleTaskToThisWeekend(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = ReminderSegmentViewModel.nextSaturday(from: now)
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
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
        recompute(collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkSetPriority(_ taskIDs: Set<PersistentIdentifier>, priority: ReminderPriority) {
        let tasksToUpdate = tasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToUpdate {
            task.priorityRawValue = priority.rawValue
        }
        try? modelContext.save()
        recompute(collapsedTasks: cachedCollapsedTasks)
    }
}
