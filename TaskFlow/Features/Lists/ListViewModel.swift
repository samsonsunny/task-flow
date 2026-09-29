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

    var ungroupedLists: [ReminderList] {
        lists.filter { $0.group == nil }
    }

    /// A list is an area's bucket when it is the area's list named "Inbox" (derived; see
    /// `ReminderList.isBucket`).
    func isBucket(_ list: ReminderList) -> Bool {
        list.isBucket
    }

    // MARK: - List CRUD

    /// Creates a list inside a specific area. There is no area picker and no fallback: a
    /// list always lands in the area the caller passes, and a locked area's identity is
    /// never altered by the operation.
    @discardableResult
    func createList(name: String, in area: ReminderListGroup) -> ReminderList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let list = ReminderList(name: trimmed)
        list.group = area
        modelContext.insert(list)
        list.assignInitialSortOrder(in: modelContext)
        try? modelContext.save()
        return list
    }

    func renameList(_ list: ReminderList, to newName: String) {
        guard !isBucket(list) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        list.name = trimmed
        try? modelContext.save()
    }

    func deleteList(_ list: ReminderList, moveTasksTo targetList: ReminderList) {
        guard !isBucket(list) else { return }
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }
        for task in listTasks {
            task.reminderList = targetList
        }
        modelContext.delete(list)
        try? modelContext.save()
    }

    func deleteListAndTasks(_ list: ReminderList) {
        guard !isBucket(list) else { return }
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

    /// Lists of an area in display order: the area's bucket pinned first, then the rest
    /// by `sortOrder`. Used for Home's section ordering and for drag-reorder.
    func orderedLists(in group: ReminderListGroup) -> [ReminderList] {
        listsInGroup(group).sorted { lhs, rhs in
            let lhsIsBucket = isBucket(lhs)
            let rhsIsBucket = isBucket(rhs)
            if lhsIsBucket != rhsIsBucket { return lhsIsBucket }
            return (lhs.sortOrder ?? "", lhs.createdAt) < (rhs.sortOrder ?? "", rhs.createdAt)
        }
    }

    // MARK: - Reorder

    /// Reorders lists within a single area. There is no cross-area reparent: a list's area
    /// is fixed at creation, so `source` must all belong to the same group.
    func moveLists(fromOffsets: IndexSet, toOffset: Int, in source: [ReminderList]) {
        guard !source.isEmpty, source.allSatisfy({ !isBucket($0) }) else { return }
        guard let areaID = source.first?.group?.persistentModelID,
              source.allSatisfy({ $0.group?.persistentModelID == areaID })
        else { return }

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

        try? modelContext.save()
    }
}

