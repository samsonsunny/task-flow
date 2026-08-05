import SwiftUI
import SwiftData

@MainActor
@Observable
final class ReminderEditorViewModel {
    private let modelContext: ModelContext

    private(set) var reminderLists: [ReminderList]
    private(set) var reminderTags: [ReminderTag]

    let task: TaskItem?
    let initialDraft: ReminderDraft
    var draft: ReminderDraft
    var isDiscardConfirmationPresented = false

    var isDirty: Bool {
        draft != initialDraft
    }

    init(
        modelContext: ModelContext,
        task: TaskItem? = nil,
        reminderLists: [ReminderList] = [],
        reminderTags: [ReminderTag] = [],
        initialDate: Date? = nil,
        initialListID: ReminderList.ID? = nil,
        initialTitle: String = ""
    ) {
        self.modelContext = modelContext
        self.reminderLists = reminderLists
        self.reminderTags = reminderTags
        self.task = task

        let initialDraft: ReminderDraft
        if let task {
            initialDraft = ReminderDraft(task: task)
        } else {
            var draft = ReminderDraft.empty
            draft.dueDate = initialDate
            draft.title = initialTitle
            initialDraft = draft
        }
        self.initialDraft = initialDraft
        self.draft = initialDraft

        if let initialListID, draft.listName.isEmpty {
            if let list = try? modelContext.model(for: initialListID) as? ReminderList {
                draft.listName = list.name
            }
        }
    }

    func update(reminderLists: [ReminderList], reminderTags: [ReminderTag]) {
        self.reminderLists = reminderLists
        self.reminderTags = reminderTags
    }

    func save() {
        guard draft.hasMeaningfulContent else { return }

        let target = task ?? TaskItem()
        ReminderDraftMapper.apply(
            draft,
            to: target,
            availableLists: reminderLists,
            availableTags: reminderTags,
            in: modelContext
        )

        if task == nil {
            if target.createdAt == nil {
                target.createdAt = Date()
            }
            if target.taskId == nil {
                target.taskId = UUID().uuidString
            }
            modelContext.insert(target)
            assignInitialSortOrder(target)
        }

        let notif = NotificationService.shared
        if draft.hasTime {
            Task {
                guard await notif.requestAuthorizationIfNeeded() else { return }
                notif.schedule(for: target)
            }
        } else {
            if let taskId = target.taskId {
                notif.cancel(taskId: taskId)
            }
        }
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
    }

    func handleClose() {
        if isDirty {
            isDiscardConfirmationPresented = true
        }
    }

    // MARK: - Subtask Operations

    func addSubtask(title: String, to parent: TaskItem) {
        let text = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let subtask = TaskItem(taskTitle: text, dueDate: nil)
        subtask.createdAt = Date()
        subtask.reminderList = parent.reminderList
        subtask.parentTask = parent
        let sorted = parent.subtasks
            .filter { $0.persistentModelID != subtask.persistentModelID }
            .sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        subtask.sortOrder = midpointOrWiden(between: sorted.last?.sortOrder, and: nil)
        modelContext.insert(subtask)
    }

    func deleteSubtask(_ subtask: TaskItem) {
        if let taskId = subtask.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        modelContext.delete(subtask)
    }

    func toggleSubtaskCompletion(_ subtask: TaskItem) {
        let next = !(subtask.isCompleted ?? false)
        subtask.isCompleted = next
        subtask.completionDate = next ? Date() : nil
        if next, let taskId = subtask.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
    }

    func rescheduleSubtask(_ subtask: TaskItem, to action: DueDateAction) {
        let calendar = Calendar.current
        switch action {
        case .none:
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.dueDate = nil
        case .today:
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.dueDate = calendar.startOfDay(for: Date())
        case .tomorrow:
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.dueDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))
        case .thisWeekend:
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.dueDate = ReminderSegmentViewModel.nextSaturday(from: Date())
        case .nextWeek:
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.dueDate = ReminderSegmentViewModel.nextMonday(from: Date())
        case .nextMonth:
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.dueDate = ReminderSegmentViewModel.nextMonth(from: Date())
        case .custom:
            break
        }
        try? modelContext.save()
    }

    func scheduleSubtask(_ subtask: TaskItem, dueDate: Date?, hasTime: Bool) {
        if let taskId = subtask.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        if let date = dueDate {
            if hasTime {
                subtask.dueDate = date
                subtask.hasTime = true
                NotificationService.shared.schedule(for: subtask)
            } else {
                subtask.dueDate = Calendar.current.startOfDay(for: date)
                subtask.hasTime = false
            }
        } else {
            subtask.dueDate = nil
        }
        try? modelContext.save()
    }

    func moveSubtask(_ subtask: TaskItem, to list: ReminderList) {
        if let taskId = subtask.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        subtask.reminderList = list
        subtask.parentTask = nil
        assignListSortOrder(for: subtask, in: list)
        try? modelContext.save()
    }

    func moveSubtaskUp(_ subtask: TaskItem) {
        reorderSubtask(subtask, direction: -1)
    }

    func moveSubtaskDown(_ subtask: TaskItem) {
        reorderSubtask(subtask, direction: 1)
    }

    func subtasks(of parent: TaskItem) -> [TaskItem] {
        parent.subtasks.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
    }

    func canMoveSubtaskUp(_ subtask: TaskItem) -> Bool {
        guard let parent = subtask.parentTask else { return false }
        return subtasks(of: parent).first?.persistentModelID != subtask.persistentModelID
    }

    func canMoveSubtaskDown(_ subtask: TaskItem) -> Bool {
        guard let parent = subtask.parentTask else { return false }
        return subtasks(of: parent).last?.persistentModelID != subtask.persistentModelID
    }

    private func reorderSubtask(_ subtask: TaskItem, direction: Int) {
        guard let parent = subtask.parentTask else { return }
        let siblings = subtasks(of: parent)
        guard let index = siblings.firstIndex(where: { $0.persistentModelID == subtask.persistentModelID }) else { return }
        let target = index + direction
        guard target >= 0 && target < siblings.count else { return }
        let other = siblings[target]
        let tmp = subtask.sortOrder
        subtask.sortOrder = other.sortOrder
        other.sortOrder = tmp
        try? modelContext.save()
    }

    private func assignListSortOrder(for task: TaskItem, in list: ReminderList) {
        guard let existing = try? modelContext.fetch(FetchDescriptor<TaskItem>()) else { return }
        let lastOrder = existing
            .filter { $0.reminderList?.persistentModelID == list.persistentModelID && $0.persistentModelID != task.persistentModelID }
            .compactMap { $0.sortOrder }
            .sorted()
            .last
        task.sortOrder = midpointOrWiden(between: lastOrder, and: nil)
    }

    // MARK: - Helpers

    private func assignInitialSortOrder(_ task: TaskItem) {
        guard let list = task.reminderList else { return }
        guard let existing = try? modelContext.fetch(FetchDescriptor<TaskItem>()) else { return }
        let lastOrder = existing
            .filter { $0.reminderList?.persistentModelID == list.persistentModelID && $0.persistentModelID != task.persistentModelID }
            .compactMap { $0.sortOrder }
            .sorted()
            .last
        task.sortOrder = midpointOrWiden(between: lastOrder, and: nil)
    }
}
