import SwiftUI
import SwiftData

/// The one-filter-at-a-time chip row above Home's list. "Recents" is the unfiltered surface —
/// every incomplete task in the area, newest first — and the date chips slice the same pool with
/// the same buckets the pushed time views use, so a Home filter and the pushed Today/Overdue
/// screen can never disagree about membership.
enum HomeFilter: String, CaseIterable, Identifiable, Hashable {
    case recents
    case today
    case tomorrow
    case overdue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recents: return "Recents"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .overdue: return "Overdue"
        }
    }

    var reminderSegment: ReminderSegment? {
        switch self {
        case .recents: return nil
        case .today: return .today
        case .tomorrow: return .tomorrow
        case .overdue: return .overdue
        }
    }
}

@MainActor
@Observable
final class HomeViewModel {
    private let modelContext: ModelContext

    private(set) var allLists: [ReminderList] = []
    private(set) var allGroups: [ReminderListGroup] = []
    private(set) var allTasks: [TaskItem] = []

    /// The area currently being browsed and captured into.
    private(set) var area: ReminderListGroup?

    /// Every task in the selected area that survives the active filter, as one flat list.
    /// "Recents" orders them most recently created first; the date filters order by due date.
    /// Lists are not a grouping level here — the list name rides along on each row's secondary
    /// line instead. Completed work is filtered out: it stays in its list and in the Completed
    /// screen, but it must not push live work down the screen.
    private(set) var tasks: [TaskItem] = []

    /// The active filter. Session-scoped like the selected area: Home opens on "Recents" and
    /// the chip row holds whatever the user last picked until the app relaunches.
    private(set) var filter: HomeFilter = .recents

    var now: Date = Date()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Update Entry Point

    func update(
        groups: [ReminderListGroup],
        lists: [ReminderList],
        allTasks: [TaskItem],
        areaID: ReminderListGroup.ID?,
        now: Date = Date()
    ) {
        self.allGroups = groups
        self.allLists = lists
        self.allTasks = allTasks
        self.now = now

        // Resolve against the live objects so an area deleted by the merge falls through
        // to Work rather than keeping a stale identifier.
        let area = groups.first { $0.persistentModelID == areaID } ?? groups.first
        self.area = area

        rebuild(areaID: area?.persistentModelID)
    }

    private func rebuild(areaID: ReminderListGroup.ID?) {
        guard let areaID, allGroups.contains(where: { $0.persistentModelID == areaID }) else {
            tasks = []
            return
        }

        let areaListIDs = Set(allLists.filter { $0.group?.persistentModelID == areaID }.map(\.persistentModelID))
        // Home is the "what's left to do" surface, so completed work leaves it. Completed
        // tasks are not lost — they stay in their list and in the Completed screen — but
        // keeping them here would push live work below a wall of finished rows.
        let inArea = allTasks.filter { task in
            guard task.isCompleted != true,
                  let listID = task.reminderList?.persistentModelID
            else { return false }
            return areaListIDs.contains(listID)
        }

        // The date chips reuse `ReminderSegmentLogic` so a filtered Home and the pushed time
        // view of the same bucket agree on every task. "Recents" keeps the full area pool,
        // newest first — a task is reachable only through the lists of the selected area, so
        // anything filed elsewhere is simply not this screen's business.
        guard let segment = filter.reminderSegment else {
            tasks = inArea.sorted { lhs, rhs in
                let lhsDate = lhs.createdAt ?? .distantPast
                let rhsDate = rhs.createdAt ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                // Tiebreak on the stable `taskId` so equal timestamps (bulk sync, seeded fixtures)
                // keep one fixed order. `persistentModelID.hashValue` would not: Swift's hashing is
                // seeded per process, so those rows would reshuffle on every relaunch.
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }
            return
        }

        tasks = ReminderSegmentLogic.sortedTasks(
            ReminderSegmentLogic.filteredTasks(inArea, for: segment, now: now),
            for: segment
        )
    }

    // MARK: - Mutations

    /// Recomputes derived state after a mutation. `onChange(of:)` in the view compares with
    /// `Equatable`, and two `@Model` instances with the same `persistentModelID` compare equal
    /// regardless of their properties — so a toggled `isCompleted` never triggers an update by
    /// itself. This explicit call is the only reliable signal.
    private func recompute() {
        update(groups: allGroups, lists: allLists, allTasks: allTasks, areaID: area?.persistentModelID, now: now)
    }

    func toggleCompletion(for task: TaskItem) {
        let next = !(task.isCompleted ?? false)
        task.isCompleted = next
        task.completionDate = next ? now : nil
        if next, let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
        recompute()
    }

    func delete(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        modelContext.delete(task)
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
        // Drop it from the snapshot first. `recompute` re-derives from `allTasks`, and a
        // deleted model is still sitting in that array until the view's `@Query` hands over a
        // fresh one — so the row would come straight back.
        allTasks.removeAll { $0.persistentModelID == task.persistentModelID }
        recompute()
    }

    // MARK: - List CRUD

    /// Creates a list inside the given area. There is no area picker: a list always lands
    /// in the area the caller names, and areas are never created from here.
    @discardableResult
    func createList(name: String, in group: ReminderListGroup) -> ReminderList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let list = ReminderList(name: trimmed)
        list.group = group
        modelContext.insert(list)
        list.assignInitialSortOrder(in: modelContext)
        try? modelContext.save()
        return list
    }

    /// The area's bucket is the only list that cannot be renamed or deleted. Bucket
    /// identity is derived from the owning area and the list name (see
    /// `ReminderList.isBucket`).
    func isBucket(_ list: ReminderList) -> Bool {
        list.isBucket
    }

    func selectArea(_ group: ReminderListGroup) {
        guard allGroups.contains(where: { $0.persistentModelID == group.persistentModelID }) else { return }
        rebuild(areaID: group.persistentModelID)
    }

    /// Applies a filter chip without touching the area. The selection survives area switches
    /// and re-pulled `@Query` snapshots because `update()` re-runs `rebuild` against it.
    func selectFilter(_ filter: HomeFilter) {
        guard self.filter != filter else { return }
        self.filter = filter
        rebuild(areaID: area?.persistentModelID)
    }
}
