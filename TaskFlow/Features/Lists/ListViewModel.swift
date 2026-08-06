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

    func createList(name: String, group: ReminderListGroup?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let list = ReminderList(name: trimmed)
        list.group = group
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

    func deleteList(_ list: ReminderList, moveTasksTo targetList: ReminderList) {
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }
        for task in listTasks {
            task.reminderList = targetList
        }
        modelContext.delete(list)
        try? modelContext.save()
    }

    func deleteListAndTasks(_ list: ReminderList) {
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }
        for task in listTasks {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            modelContext.delete(task)
        }
        modelContext.delete(list)
        try? modelContext.save()
    }

    func listsInGroup(_ group: ReminderListGroup) -> [ReminderList] {
        lists.filter { $0.group?.persistentModelID == group.persistentModelID }
    }

    // MARK: - Reorder

    func moveLists(fromOffsets: IndexSet, toOffset: Int, in source: [ReminderList], group: ReminderListGroup? = nil) {
        var mutableLists = source
        let sortedFrom = fromOffsets.sorted()

        let moved = Array(sortedFrom.reversed().map { mutableLists.remove(at: $0) }.reversed())
        let insertAt = min(toOffset, mutableLists.count)

        mutableLists.insert(contentsOf: moved, at: insertAt)

        var lower = insertAt > 0 ? mutableLists[insertAt - 1].sortOrder : nil
        for i in insertAt..<(insertAt + moved.count) {
            let upper = (i + 1) < mutableLists.count ? mutableLists[i + 1].sortOrder : nil

            if let existing = moved[i - insertAt].sortOrder, isBetween(existing, lower: lower, upper: upper) {
                mutableLists[i].sortOrder = existing
            } else {
                mutableLists[i].sortOrder = midpointOrWiden(between: lower, and: upper)
            }

            lower = mutableLists[i].sortOrder
        }

        if let group {
            for list in mutableLists {
                list.group = group
            }
        }

        try? modelContext.save()
    }

    func moveGroups(fromOffsets: IndexSet, toOffset: Int) {
        var mutableGroups = groups
        let sortedFrom = fromOffsets.sorted()

        let moved = Array(sortedFrom.reversed().map { mutableGroups.remove(at: $0) }.reversed())
        let insertAt = min(toOffset, mutableGroups.count)

        mutableGroups.insert(contentsOf: moved, at: insertAt)

        var lower = insertAt > 0 ? mutableGroups[insertAt - 1].sortOrder : nil
        for i in insertAt..<(insertAt + moved.count) {
            let upper = (i + 1) < mutableGroups.count ? mutableGroups[i + 1].sortOrder : nil

            if let existing = moved[i - insertAt].sortOrder, isBetween(existing, lower: lower, upper: upper) {
                mutableGroups[i].sortOrder = existing
            } else {
                mutableGroups[i].sortOrder = midpointOrWiden(between: lower, and: upper)
            }

            lower = mutableGroups[i].sortOrder
        }

        try? modelContext.save()
    }

    // MARK: - List Group Assignment

    func assignListToGroup(_ list: ReminderList, group: ReminderListGroup?) {
        list.group = group
        try? modelContext.save()
    }

    // MARK: - Group CRUD

    func createGroup(name: String, sourceList: ReminderList?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let group = ReminderListGroup(name: trimmed)
        modelContext.insert(group)
        group.assignInitialSortOrder(in: modelContext)
        if let sourceList {
            sourceList.group = group
        }
        try? modelContext.save()
    }

    func renameGroup(_ group: ReminderListGroup, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        group.name = trimmed
        try? modelContext.save()
    }

    func deleteGroup(_ group: ReminderListGroup) {
        let groupLists = lists.filter { $0.group?.persistentModelID == group.persistentModelID }
        for list in groupLists {
            let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }
            for task in listTasks {
                if let taskId = task.taskId {
                    NotificationService.shared.cancel(taskId: taskId)
                }
                modelContext.delete(task)
            }
            modelContext.delete(list)
        }
        modelContext.delete(group)
        try? modelContext.save()
    }
}

