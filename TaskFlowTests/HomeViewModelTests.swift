import Foundation
import Testing
import SwiftData
@testable import TaskFlow

/// Home is a single flat, recency-sorted, area-scoped list. These lock in the three rules
/// that make it that: area scoping, recency, and no completed work.
@MainActor
struct HomeViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = TaskPreviewData.container()
        return ModelContext(container)
    }

    private func insertArea(_ name: String, order: String, into context: ModelContext) -> ReminderListGroup {
        let area = ReminderListGroup(name: name, sortOrder: order)
        context.insert(area)
        return area
    }

    private func insertList(_ name: String, into area: ReminderListGroup, order: String, in context: ModelContext) -> ReminderList {
        let list = ReminderList(name: name, sortOrder: order, group: area)
        context.insert(list)
        return list
    }

    private func insertTask(
        _ title: String,
        into list: ReminderList,
        createdAt: Date,
        completed: Bool = false,
        in context: ModelContext
    ) -> TaskItem {
        // `TaskItem.init` takes no relationships, so the list is assigned after construction.
        // Area scoping reads the list's `group`, so the task itself carries no area.
        let task = TaskItem(taskTitle: title, createdAt: createdAt)
        task.reminderList = list
        task.isCompleted = completed
        context.insert(task)
        return task
    }

    private func insertTask(
        _ title: String,
        into list: ReminderList,
        createdAt: Date,
        dueDate: Date,
        hasTime: Bool = false,
        completed: Bool = false,
        in context: ModelContext
    ) -> TaskItem {
        let task = insertTask(title, into: list, createdAt: createdAt, completed: completed, in: context)
        task.dueDate = dueDate
        task.hasTime = hasTime
        return task
    }

    private func update(
        _ vm: HomeViewModel,
        groups: [ReminderListGroup],
        lists: [ReminderList],
        tasks: [TaskItem],
        area: ReminderListGroup,
        now: Date = Date()
    ) {
        vm.update(groups: groups, lists: lists, allTasks: tasks, areaID: area.persistentModelID, now: now)
    }

    // MARK: - Area scoping

    @Test func showsOnlyTasksFiledInTheSelectedArea() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let personal = insertArea("Personal", order: "b", into: context)
        let workInbox = insertList("Inbox", into: work, order: "m", in: context)
        let personalInbox = insertList("Inbox", into: personal, order: "m", in: context)
        let workTask = insertTask("Work thing", into: workInbox, createdAt: .now, in: context)
        insertTask("Personal thing", into: personalInbox, createdAt: .now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work, personal], lists: [workInbox, personalInbox], tasks: [workTask], area: work)

        #expect(vm.tasks.map(\.safeTitle) == ["Work thing"])
    }

    /// A task in a list of the other area is not reachable by switching away — it must not
    /// leak into the selected area's list.
    @Test func switchingAreasSwapsTheVisibleTasks() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let personal = insertArea("Personal", order: "b", into: context)
        let workInbox = insertList("Inbox", into: work, order: "m", in: context)
        let personalInbox = insertList("Inbox", into: personal, order: "m", in: context)
        let workTask = insertTask("Work thing", into: workInbox, createdAt: .now, in: context)
        let personalTask = insertTask("Personal thing", into: personalInbox, createdAt: .now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work, personal], lists: [workInbox, personalInbox], tasks: [workTask, personalTask], area: personal)

        #expect(vm.tasks.map(\.safeTitle) == ["Personal thing"])
    }

    // MARK: - Ordering

    @Test func ordersNewestCreatedFirst() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let oldest = insertTask("Oldest", into: inbox, createdAt: base, in: context)
        let newest = insertTask("Newest", into: inbox, createdAt: base.addingTimeInterval(200), in: context)
        let middle = insertTask("Middle", into: inbox, createdAt: base.addingTimeInterval(100), in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [oldest, middle, newest], area: work)

        #expect(vm.tasks.map(\.safeTitle) == ["Newest", "Middle", "Oldest"])
    }

    /// Two tasks created in the same instant must not swap places between updates.
    @Test func equalTimestampsKeepAStableOrder() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let sameInstant = Date(timeIntervalSince1970: 1_700_000_000)
        let first = insertTask("First", into: inbox, createdAt: sameInstant, in: context)
        let second = insertTask("Second", into: inbox, createdAt: sameInstant, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [first, second], area: work)
        let initial = vm.tasks.map(\.taskId)

        // Re-derive from the reversed input: a stable tiebreak must not depend on input order.
        update(vm, groups: [work], lists: [inbox], tasks: [second, first], area: work)

        #expect(vm.tasks.map(\.taskId) == initial)
    }

    // MARK: - Completed work

    @Test func hidesCompletedTasks() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let pending = insertTask("Still to do", into: inbox, createdAt: .now, in: context)
        insertTask("Already done", into: inbox, createdAt: .now.addingTimeInterval(-50), completed: true, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [pending], area: work)

        #expect(vm.tasks.map(\.safeTitle) == ["Still to do"])
    }

    /// Completing from Home must remove the row straight away. `@Model` instances compare
    /// equal by `persistentModelID`, so nothing re-derives the list unless the ViewModel
    /// recomputes explicitly.
    @Test func completingATaskRemovesItFromTheList() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let task = insertTask("Do the thing", into: inbox, createdAt: .now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [task], area: work)
        #expect(vm.tasks.count == 1)

        vm.toggleCompletion(for: task)

        #expect(task.isCompleted == true)
        #expect(vm.tasks.isEmpty, "Completed task stayed on Home until some other refresh")
    }

    @Test func reopeningATaskBringsItBack() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let task = insertTask("Do the thing", into: inbox, createdAt: .now, completed: true, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [task], area: work)
        #expect(vm.tasks.isEmpty)

        vm.toggleCompletion(for: task)

        #expect(vm.tasks.map(\.safeTitle) == ["Do the thing"])
    }

    @Test func deletingATaskRemovesItFromTheList() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let task = insertTask("Do the thing", into: inbox, createdAt: .now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [task], area: work)

        vm.delete(task)

        #expect(vm.tasks.isEmpty)
    }

    // MARK: - Filters

    /// "Recents" is the unfiltered surface: every incomplete task in the area, newest first.
    @Test func recentsShowsTheWholeAreaPool() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let dueToday = insertTask("Due today", into: inbox, createdAt: now, dueDate: now, in: context)
        let dueNextWeek = insertTask("Due next week", into: inbox, createdAt: now.addingTimeInterval(60), dueDate: now.addingTimeInterval(7 * 86_400), in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [dueToday, dueNextWeek], area: work, now: now)

        #expect(vm.filter == .recents)
        #expect(vm.tasks.map(\.safeTitle) == ["Due next week", "Due today"])
    }

    @Test func todayFilterShowsOnlyTasksDueToday() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let overdue = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let dueToday = insertTask("Due today", into: inbox, createdAt: now, dueDate: now, in: context)
        insertTask("Due tomorrow", into: inbox, createdAt: now, dueDate: tomorrow, in: context)
        insertTask("Overdue", into: inbox, createdAt: now, dueDate: overdue, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [dueToday], area: work, now: now)

        vm.selectFilter(.today)
        #expect(vm.filter == .today)
        #expect(vm.tasks.map(\.safeTitle) == ["Due today"])
    }

    @Test func tomorrowFilterShowsOnlyTasksDueTomorrow() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let dueTomorrow = insertTask("Due tomorrow", into: inbox, createdAt: now, dueDate: tomorrow, in: context)
        insertTask("Due today", into: inbox, createdAt: now, dueDate: now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [dueTomorrow], area: work, now: now)

        vm.selectFilter(.tomorrow)
        #expect(vm.tasks.map(\.safeTitle) == ["Due tomorrow"])
    }

    @Test func overdueFilterShowsOnlyOverdueTasks() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let overdue = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let veryOverdue = Calendar.current.date(byAdding: .day, value: -5, to: now)!
        insertTask("Most overdue", into: inbox, createdAt: now, dueDate: veryOverdue, in: context)
        let overdueTask = insertTask("Overdue", into: inbox, createdAt: now, dueDate: overdue, in: context)
        insertTask("Due today", into: inbox, createdAt: now, dueDate: now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [overdueTask], area: work, now: now)

        vm.selectFilter(.overdue)
        #expect(vm.tasks.map(\.safeTitle) == ["Overdue"])
    }

    /// A dated chip must respect the same incomplete-only rule as Recents.
    @Test func dateFiltersStillHideCompletedTasks() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let overdue = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        insertTask("Done", into: inbox, createdAt: now, dueDate: overdue, completed: true, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [], area: work, now: now)

        vm.selectFilter(.overdue)
        #expect(vm.tasks.isEmpty)
    }

    /// The selection is session-scoped: it must survive an area switch and a re-pulled query.
    @Test func filterSurvivesAreaSwitchAndReupdate() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let personal = insertArea("Personal", order: "b", into: context)
        let workInbox = insertList("Inbox", into: work, order: "m", in: context)
        let personalInbox = insertList("Inbox", into: personal, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let workToday = insertTask("Work today", into: workInbox, createdAt: now, dueDate: now, in: context)
        let personalTomorrow = insertTask("Personal tomorrow", into: personalInbox, createdAt: now, dueDate: tomorrow, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work, personal], lists: [workInbox, personalInbox], tasks: [workToday, personalTomorrow], area: work, now: now)
        vm.selectFilter(.tomorrow)
        #expect(vm.tasks.isEmpty)

        update(vm, groups: [work, personal], lists: [workInbox, personalInbox], tasks: [workToday, personalTomorrow], area: personal, now: now)
        #expect(vm.filter == .tomorrow)
        #expect(vm.tasks.map(\.safeTitle) == ["Personal tomorrow"])
    }

    /// A dated chip keeps its pool ordered by due date, not recency, so the most urgent row is
    /// at the top.
    @Test func todayFilterOrdersByDueDate() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // "Later" was created more recently, so a recency sort would put it first. The dated
        // chip must instead lead with the earlier due time.
        let earlier = insertTask("Earlier", into: inbox, createdAt: now, dueDate: now, hasTime: true, in: context)
        let later = insertTask("Later", into: inbox, createdAt: now.addingTimeInterval(90), dueDate: now.addingTimeInterval(3 * 3_600), hasTime: true, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [earlier, later], area: work, now: now)

        vm.selectFilter(.today)
        #expect(vm.tasks.map(\.safeTitle) == ["Earlier", "Later"])
    }

    // MARK: - Degenerate input

    @Test func anAreaWithNoListsShowsNothing() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let personal = insertArea("Personal", order: "b", into: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work, personal], lists: [], tasks: [], area: work)

        #expect(vm.tasks.isEmpty)
    }

    /// A task with no list at all cannot belong to an area, so it is never shown.
    @Test func orphansAreNotShown() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let orphan = TaskItem(taskTitle: "Floating", createdAt: .now)
        context.insert(orphan)
        let filed = insertTask("Filed", into: inbox, createdAt: .now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [filed, orphan], area: work)

        #expect(vm.tasks.map(\.safeTitle) == ["Filed"])
    }
}
