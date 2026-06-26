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
}
