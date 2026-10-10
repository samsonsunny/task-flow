import SwiftUI
import SwiftData

/// One due-date bucket on Home. Reuses `ReminderSegment` so Home's section headers share the
/// same title, tint, and icon as the pushed time screens. `.tomorrow` never appears here: the
/// dated list folds tomorrow into `.upcoming` so overdue leads, then today, then everything else.
struct HomeTaskSection: Identifiable {
    let segment: ReminderSegment
    let tasks: [TaskItem]

    var id: ReminderSegment { segment }
    var title: String { segment.title }
    var tint: Color { segment.tintColor }
    var iconName: String { segment.iconName }
}

/// The two halves of Home, switched by a segmented control instead of a pushed page.
/// `.planned` is the due-date schedule (overdue / today / upcoming); `.unplanned` collects the
/// incomplete tasks that carry no due date.
enum HomeScope: String, CaseIterable, Identifiable, Hashable {
    case planned
    case unplanned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned: return "Planned"
        case .unplanned: return "Unplanned"
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

    /// The selected area's incomplete *dated* tasks, split into overdue / today / upcoming and
    /// sorted by due date within each bucket. Today is always present — even when empty — so the
    /// Planned half never reads as broken; overdue and upcoming drop away when they carry no work.
    /// Lists are not a grouping level here — the list name rides along on each row's secondary line.
    private(set) var datedSections: [HomeTaskSection] = []

    /// The selected area's incomplete tasks that carry no due date — the Unplanned half of
    /// Home. Newest created first.
    private(set) var undatedTasks: [TaskItem] = []

    /// Which half of Home is showing. Session-scoped like the selected area: Home opens on
    /// Planned and holds whatever the user last picked until the app relaunches.
    private(set) var scope: HomeScope = .planned

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
            datedSections = []
            undatedTasks = []
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

        // A task is reachable only through the lists of the selected area, so anything filed
        // elsewhere is simply not this screen's business. Dated work is bucketed by urgency;
        // undated work lives behind the call to action instead of cluttering the schedule.
        datedSections = Self.sections(from: inArea, now: now)
        undatedTasks = Self.undated(from: inArea)
    }

    // MARK: - Sectioning

    /// Splits dated tasks into overdue / today / upcoming buckets. Today is kept even when empty
    /// so the Planned half always has an anchor; overdue and upcoming are dropped when empty.
    /// `.upcoming` here means "anything after today" — the pushed Upcoming screen starts two
    /// days out, but Home is the full schedule, so tomorrow belongs in the future bucket.
    static func sections(
        from tasks: [TaskItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [HomeTaskSection] {
        let todayStart = calendar.startOfDay(for: now)
        var overdue: [TaskItem] = []
        var today: [TaskItem] = []
        var upcoming: [TaskItem] = []

        for task in tasks {
            guard let dueDate = task.dueDate else { continue }
            let dueStart = calendar.startOfDay(for: dueDate)
            let isOverdue = task.hasTime == true ? dueDate < now : dueStart < todayStart
            if isOverdue {
                overdue.append(task)
            } else if dueStart == todayStart {
                today.append(task)
            } else {
                upcoming.append(task)
            }
        }

        // Overdue leads with the oldest deadline, then today, then the soonest future work.
        // Every bucket reads top-to-bottom by due date; ties break on the stable `taskId` so
        // equal dates never reshuffle between updates.
        return [
            HomeTaskSection(segment: .overdue, tasks: sortedByDueDate(overdue)),
            HomeTaskSection(segment: .today, tasks: sortedByDueDate(today)),
            HomeTaskSection(segment: .upcoming, tasks: sortedByDueDate(upcoming)),
        ].filter { $0.segment == .today || !$0.tasks.isEmpty }
    }

    /// Incomplete tasks with no due date, newest created first.
    static func undated(from tasks: [TaskItem]) -> [TaskItem] {
        tasks
            .filter { $0.dueDate == nil }
            .sorted { lhs, rhs in
                let lhsDate = lhs.createdAt ?? .distantPast
                let rhsDate = rhs.createdAt ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                // Tiebreak on the stable `taskId` so equal timestamps (bulk sync, seeded
                // fixtures) keep one fixed order. `persistentModelID.hashValue` would not:
                // Swift's hashing is seeded per process, so those rows would reshuffle on
                // every relaunch.
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }
    }

    private static func sortedByDueDate(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { lhs, rhs in
            let lhsDate = lhs.dueDate ?? .distantFuture
            let rhsDate = rhs.dueDate ?? .distantFuture
            if lhsDate != rhsDate { return lhsDate < rhsDate }
            return (lhs.taskId ?? "") < (rhs.taskId ?? "")
        }
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

    /// Switches between the Planned and Unplanned halves. Both pools are always derived, so
    /// this only flips which one the view reads — no recompute needed.
    func selectScope(_ scope: HomeScope) {
        guard self.scope != scope else { return }
        self.scope = scope
    }
}
