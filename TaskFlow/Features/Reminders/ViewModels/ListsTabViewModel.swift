import SwiftUI
import SwiftData

@MainActor
@Observable
final class ListsTabViewModel {
    private let modelContext: ModelContext

    private(set) var lists: [ReminderList] = []
    private(set) var groups: [ReminderListGroup] = []
    private(set) var allTasks: [TaskItem] = []

    // MARK: - Dialog State

    var isCreatingList = false
    var newListName = ""
    var isRenamePresented = false
    var renameList: ReminderList?
    var renameText = ""
    var deleteList: ReminderList?
    var isCreatingGroup = false
    var newGroupName = ""
    var groupSourceList: ReminderList?
    var renameGroup: ReminderListGroup?
    var isGroupRenamePresented = false
    var groupRenameText = ""
    var deleteGroup: ReminderListGroup?

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Update Entry Point

    func update(lists: [ReminderList], groups: [ReminderListGroup], allTasks: [TaskItem]) {
        self.lists = lists
        self.groups = groups
        self.allTasks = allTasks
    }

    // MARK: - Derived Properties

    var defaultList: ReminderList? {
        lists.first(where: { $0.name == ReminderDefaults.defaultListName })
    }

    var ungroupedLists: [ReminderList] {
        lists.filter { $0.group == nil && $0.name != ReminderDefaults.defaultListName }
    }

    // MARK: - List CRUD

    func createList(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let list = ReminderList(name: trimmed)
        modelContext.insert(list)
        list.assignInitialSortOrder(in: modelContext)
        try? modelContext.save()
    }

    func renameList(_ list: ReminderList, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        list.name = trimmed
        try? modelContext.save()
    }

    func deleteList(_ list: ReminderList, moveTasksToDefault: Bool) {
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }

        if moveTasksToDefault {
            if let defaultList {
                for task in listTasks {
                    task.reminderList = defaultList
                }
            }
        } else {
            for task in listTasks {
                if let taskId = task.taskId {
                    NotificationService.shared.cancel(taskId: taskId)
                }
                modelContext.delete(task)
            }
        }

        modelContext.delete(list)
        try? modelContext.save()
    }

    func listsInGroup(_ group: ReminderListGroup) -> [ReminderList] {
        lists.filter { $0.group?.persistentModelID == group.persistentModelID }
    }
}
