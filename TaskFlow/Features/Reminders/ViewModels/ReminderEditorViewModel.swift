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
    }

    func handleClose() {
        if isDirty {
            isDiscardConfirmationPresented = true
        }
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
        task.sortOrder = midpoint(between: lastOrder, and: nil)
    }
}
