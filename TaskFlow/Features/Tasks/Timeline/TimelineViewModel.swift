import SwiftUI
import SwiftData

@MainActor
@Observable
final class ReminderSegmentViewModel {
    private let modelContext: ModelContext
    let segment: ReminderSegment
    private(set) var overdueTasks: [TaskItem] = []

    private(set) var now: Date = Date()
    private(set) var justCompleted: Set<String> = []

    private(set) var filteredTasks: [TaskItem] = []
    private(set) var flatNodes: [FlatTaskNode] = []
    private var cachedCollapsedTasks: Set<PersistentIdentifier> = []
    private(set) var groupedSections: [TaskUIModel.DatedSection] = []
    private(set) var upcomingGroups: [TaskUIModel.UpcomingGroup] = []
    private(set) var sortedFlatTasks: [TaskItem] = []
    private(set) var listSections: [ListSection] = []

    private(set) var lists: [ReminderList] = []
    private(set) var allTasks: [TaskItem] = []

    private static let dailyOrderKeyPrefix = "daily-order-"

    init(modelContext: ModelContext, segment: ReminderSegment) {
        self.modelContext = modelContext
        self.segment = segment
    }

    // MARK: - Daily Order (UserDefaults)

    private var dailyOrderKey: String {
        Self.dailyOrderKeyPrefix + segment.rawValue
    }

    private var overdueOrderKey: String {
        Self.dailyOrderKeyPrefix + "overdue"
    }

    func readDailyOrder(forKey key: String? = nil) -> [String: Int] {
        let ids = UserDefaults.standard.stringArray(forKey: key ?? dailyOrderKey) ?? []
        return Dictionary(uniqueKeysWithValues: ids.enumerated().map { ($0.element, $0.offset) })
    }

    func readDailyOrderArray(forKey key: String? = nil) -> [String] {
        UserDefaults.standard.stringArray(forKey: key ?? dailyOrderKey) ?? []
    }

    func writeDailyOrder(_ order: [String], forKey key: String? = nil) {
        UserDefaults.standard.set(order, forKey: key ?? dailyOrderKey)
    }

    func moveTasks(fromOffsets: IndexSet, toOffset: Int, in source: [TaskItem], orderKey: String? = nil) {
        let key = orderKey ?? dailyOrderKey
        var mutableTasks = source
        let sortedFrom = fromOffsets.sorted()

        print("[REORDER]   moveTasks(key=\(key)) | fromOffsets=\(fromOffsets) toOffset=\(toOffset)")
        print("[REORDER]   source (roots in display order): \(source.map(\.safeTitle))")
        print("[REORDER]   existing daily-order array count: \(UserDefaults.standard.stringArray(forKey: key)?.count ?? 0)")

        let moved = Array(sortedFrom.reversed().map { mutableTasks.remove(at: $0) }.reversed())
        let insertAt = min(toOffset, mutableTasks.count)

        mutableTasks.insert(contentsOf: moved, at: insertAt)

        print("[REORDER]   removed=\(moved.map(\.safeTitle)) insertAt=\(insertAt) (unadjusted) | new order=\(mutableTasks.map(\.safeTitle))")

        let newOrder = mutableTasks.map { $0.persistentModelID.stableKey }
        writeDailyOrder(newOrder, forKey: key)
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
    }

    func refreshNow(now: Date = Date()) {
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
    }

    func update(tasks: [TaskItem], lists: [ReminderList], now: Date = Date(), collapsedTasks: Set<PersistentIdentifier> = []) {
        self.now = now
        self.lists = lists
        self.allTasks = tasks
        self.cachedCollapsedTasks = collapsedTasks
        self.overdueTasks = ReminderSegmentLogic.filteredTasks(tasks, for: .overdue, now: now)
        self.filteredTasks = ReminderSegmentLogic.filteredTasks(tasks, for: segment, now: now)
        self.groupedSections = ReminderSegmentLogic.datedSections(from: tasks, for: segment, now: now)
        self.upcomingGroups = ReminderSegmentLogic.upcomingGroups(from: tasks, now: now)
        let displayable = (self.filteredTasks + tasks.filter { justCompleted.contains($0.taskId ?? "") })
        let customOrderIndex = readDailyOrder()
        if !customOrderIndex.isEmpty {
            print("[REORDER]   update(segment=\(segment.rawValue)) read back \(customOrderIndex.count) daily-order ids | filteredRoots=\(ReminderSegmentLogic.sortedTasks(displayable, for: segment, customOrderIndex: customOrderIndex).map(\.safeTitle))")
        }
        self.sortedFlatTasks = ReminderSegmentLogic.sortedTasks(displayable, for: segment, customOrderIndex: customOrderIndex)
        self.listSections = buildListSections(from: lists)
        rebuildTree(collapsedTasks: collapsedTasks)
    }

    private func rebuildTree(collapsedTasks: Set<PersistentIdentifier>) {
        let filterBase = filteredTasks + allTasks.filter { justCompleted.contains($0.taskId ?? "") }
        let topLevelTasks = filterBase.filter { $0.parentTask == nil || $0.dueDate != nil }
        let customOrderIndex = readDailyOrder()
        let sortedTasks = ReminderSegmentLogic.sortedTasks(topLevelTasks, for: segment, customOrderIndex: customOrderIndex)
        flatNodes = TaskTreeFlattener.flatten(roots: sortedTasks, collapsed: collapsedTasks, nestSubtasks: false)
    }

    var rootedNodes: [(root: FlatTaskNode, children: [FlatTaskNode])] {
        var result: [(root: FlatTaskNode, children: [FlatTaskNode])] = []
        var currentChildren: [FlatTaskNode] = []
        for node in flatNodes {
            if node.depth == 0 {
                if !currentChildren.isEmpty, let lastIdx = result.indices.last {
                    result[lastIdx].children = currentChildren
                }
                result.append((root: node, children: []))
                currentChildren = []
            } else {
                currentChildren.append(node)
            }
        }
        if !currentChildren.isEmpty, let lastIdx = result.indices.last {
            result[lastIdx].children = currentChildren
        }
        return result
    }

    var overdueRootedNodes: (roots: [TaskItem], nodes: [FlatTaskNode]) {
        let overdueRoots = overdueTasks.filter { $0.parentTask == nil || $0.dueDate != nil }
        let sorted = ReminderSegmentLogic.sortedTasks(overdueRoots, for: .overdue, customOrderIndex: readDailyOrder(forKey: overdueOrderKey))
        let nodes = sorted.map { FlatTaskNode(id: $0.persistentModelID, task: $0, depth: 0, subtaskSummary: $0.subtaskSummary) }
        return (sorted, nodes)
    }

    /// Overdue tasks that are shown as rows — dated subtasks surface flat alongside top-level tasks.
    var overdueDisplayTasks: [TaskItem] {
        overdueTasks.filter { $0.parentTask == nil || $0.dueDate != nil }
    }

    /// Build flat nodes from section-scoped tasks without nesting.
    /// Dated subtasks surface flat at depth 0 alongside top-level tasks.
    func flatNodes(for sectionTasks: [TaskItem], collapsedTasks: Set<PersistentIdentifier>) -> [FlatTaskNode] {
        TaskTreeFlattener.flatten(roots: sectionTasks.filter { $0.parentTask == nil || $0.dueDate != nil }, collapsed: collapsedTasks, nestSubtasks: false)
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
        case .today, .tomorrow: return false
        case .upcoming, .overdue: return true
        }
    }

    // MARK: - Mutations

    func toggleCompletion(for task: TaskItem) {
        let next = !(task.isCompleted ?? false)
        if next {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if let id = task.taskId {
                justCompleted.insert(id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak task] in
                    guard let self, let task, task.isCompleted == true else { return }
                    self.justCompleted.remove(id)
                    self.update(tasks: self.allTasks, lists: self.lists, now: self.now)
                }
            }
        } else if let id = task.taskId {
            justCompleted.remove(id)
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
            if next, let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func commitQuickCapture(text: String, notes: String = "", captureDate: Date?) {
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
        task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task.reminderList = resolvedQuickCaptureList()
        modelContext.insert(task)
        try? modelContext.save()
        allTasks.append(task)
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
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
        allTasks.removeAll { $0.persistentModelID == task.persistentModelID }
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func moveTask(_ task: TaskItem, to list: ReminderList) {
        task.reminderList = list
        task.parentTask = nil
        assignSortOrder(for: task, in: list)
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
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
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleToToday(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = Calendar.current.startOfDay(for: now)
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleToTomorrow(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        task.dueDate = calendar.date(byAdding: .day, value: 1, to: todayStart)
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleToNextDay(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let taskDueStart = task.dueDate.map { calendar.startOfDay(for: $0) } ?? todayStart
        let baseDate = max(taskDueStart, todayStart)
        task.dueDate = calendar.date(byAdding: .day, value: 1, to: baseDate)
        task.deferCount = (task.deferCount ?? 0) + 1
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleToNextWeek(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = Self.nextMonday(from: now)
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleToThisWeekend(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = Self.nextSaturday(from: now)
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    func rescheduleToNone(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = nil
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now)
        BadgeService.update(modelContext: modelContext)
    }

    static func nextMonday(from date: Date) -> Date {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: todayStart)
        let daysUntilMonday: Int
        switch weekday {
        case 2: daysUntilMonday = 7
        case 3: daysUntilMonday = 6
        case 4: daysUntilMonday = 5
        case 5: daysUntilMonday = 4
        case 6: daysUntilMonday = 3
        case 7: daysUntilMonday = 2
        case 1: daysUntilMonday = 1
        default: daysUntilMonday = 7
        }
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: todayStart)!
    }

    /// Saturday of the current or upcoming weekend. Returns today when the date
    /// already falls on a weekend (Saturday or Sunday), otherwise the next Saturday.
    static func nextSaturday(from date: Date, calendar: Calendar = .current) -> Date {
        let todayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: todayStart)
        let daysUntilSaturday: Int
        switch weekday {
        case 1, 7: daysUntilSaturday = 0
        default: daysUntilSaturday = 7 - weekday
        }
        return calendar.date(byAdding: .day, value: daysUntilSaturday, to: todayStart)!
    }

    // MARK: - Bulk Operations
    func bulkRescheduleToToday(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToReschedule = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = Calendar.current.startOfDay(for: now)
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToTomorrow(_ taskIDs: Set<PersistentIdentifier>) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        let tasksToReschedule = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = tomorrow
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToNextWeek(_ taskIDs: Set<PersistentIdentifier>) {
        let nextMon = Self.nextMonday(from: now)
        let tasksToReschedule = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = nextMon
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToThisWeekend(_ taskIDs: Set<PersistentIdentifier>) {
        let saturday = Self.nextSaturday(from: now)
        let tasksToReschedule = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = saturday
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToDate(_ taskIDs: Set<PersistentIdentifier>, dueDate: Date?, hasTime: Bool) {
        let tasksToReschedule = allTasks.filter { taskIDs.contains($0.persistentModelID) }
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
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkRescheduleToNone(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToReschedule = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToReschedule {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            task.dueDate = nil
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkMoveToList(_ taskIDs: Set<PersistentIdentifier>, list: ReminderList) {
        let tasksToMove = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToMove {
            task.reminderList = list
            task.parentTask = nil
            assignSortOrder(for: task, in: list)
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
    }

    func bulkToggleCompletion(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToToggle = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToToggle {
            let next = !(task.isCompleted ?? false)
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
            if next, let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkDelete(_ taskIDs: Set<PersistentIdentifier>) {
        let tasksToDelete = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToDelete {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            modelContext.delete(task)
        }
        try? modelContext.save()
        for id in taskIDs {
            allTasks.removeAll { $0.persistentModelID == id }
        }
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
        BadgeService.update(modelContext: modelContext)
    }

    func bulkSetPriority(_ taskIDs: Set<PersistentIdentifier>, priority: ReminderPriority) {
        let tasksToUpdate = allTasks.filter { taskIDs.contains($0.persistentModelID) }
        for task in tasksToUpdate {
            task.priorityRawValue = priority.rawValue
        }
        try? modelContext.save()
        update(tasks: allTasks, lists: lists, now: now, collapsedTasks: cachedCollapsedTasks)
    }
}
