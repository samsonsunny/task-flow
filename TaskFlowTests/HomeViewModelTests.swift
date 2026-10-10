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

        #expect(vm.undatedTasks.map(\.safeTitle) == ["Work thing"])
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

        #expect(vm.undatedTasks.map(\.safeTitle) == ["Personal thing"])
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

        #expect(vm.undatedTasks.map(\.safeTitle) == ["Newest", "Middle", "Oldest"])
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
        let initial = vm.undatedTasks.map(\.taskId)

        // Re-derive from the reversed input: a stable tiebreak must not depend on input order.
        update(vm, groups: [work], lists: [inbox], tasks: [second, first], area: work)

        #expect(vm.undatedTasks.map(\.taskId) == initial)
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

        #expect(vm.undatedTasks.map(\.safeTitle) == ["Still to do"])
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
        #expect(vm.undatedTasks.count == 1)

        vm.toggleCompletion(for: task)

        #expect(task.isCompleted == true)
        #expect(vm.undatedTasks.isEmpty, "Completed task stayed on Home until some other refresh")
    }

    @Test func reopeningATaskBringsItBack() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let task = insertTask("Do the thing", into: inbox, createdAt: .now, completed: true, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [task], area: work)
        #expect(vm.undatedTasks.isEmpty)

        vm.toggleCompletion(for: task)

        #expect(vm.undatedTasks.map(\.safeTitle) == ["Do the thing"])
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

        #expect(vm.undatedTasks.isEmpty)
    }

    // MARK: - Due-date sectioning

    /// Overdue leads, then today, then future work — each task lands in exactly one bucket.
    @Test func splitsDatedWorkIntoOverdueTodayAndUpcoming() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let overdueDate = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: now)!
        let overdue = insertTask("Overdue", into: inbox, createdAt: now, dueDate: overdueDate, in: context)
        let today = insertTask("Today", into: inbox, createdAt: now, dueDate: now, in: context)
        let future = insertTask("Future", into: inbox, createdAt: now, dueDate: futureDate, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [overdue, today, future], area: work, now: now)

        #expect(vm.datedSections.map(\.segment) == [.overdue, .today, .upcoming])
        #expect(vm.datedSections.map { $0.tasks.map(\.safeTitle) } == [["Overdue"], ["Today"], ["Future"]])
    }

    /// A task due tomorrow is future work — Home is the whole schedule, so it must not be
    /// dropped the way the pushed Upcoming screen (which starts two days out) would.
    @Test func upcomingIncludesTomorrow() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let task = insertTask("Tomorrow", into: inbox, createdAt: now, dueDate: tomorrow, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [task], area: work, now: now)

        #expect(vm.datedSections.count == 1)
        #expect(vm.datedSections.first?.segment == .upcoming)
        #expect(vm.datedSections.first?.tasks.map(\.safeTitle) == ["Tomorrow"])
    }

    /// Buckets read top-to-bottom by due date: the most overdue leads, the soonest future leads.
    @Test func ordersEachBucketByDueDate() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let veryOverdue = Calendar.current.date(byAdding: .day, value: -5, to: now)!
        let slightlyOverdue = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let soon = Calendar.current.date(byAdding: .day, value: 2, to: now)!
        let later = Calendar.current.date(byAdding: .day, value: 6, to: now)!
        let a = insertTask("Very overdue", into: inbox, createdAt: now, dueDate: veryOverdue, in: context)
        let b = insertTask("Slightly overdue", into: inbox, createdAt: now, dueDate: slightlyOverdue, in: context)
        let c = insertTask("Soon", into: inbox, createdAt: now, dueDate: soon, in: context)
        let d = insertTask("Later", into: inbox, createdAt: now, dueDate: later, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [d, c, b, a], area: work, now: now)

        #expect(vm.datedSections.map { $0.tasks.map(\.safeTitle) } == [["Very overdue", "Slightly overdue"], ["Soon", "Later"]])
    }

    /// Undated work never enters the schedule — it is reachable only through the CTA pool.
    @Test func keepsUndatedWorkOutOfTheSchedule() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let undated = insertTask("No date", into: inbox, createdAt: now, in: context)
        let dated = insertTask("Dated", into: inbox, createdAt: now.addingTimeInterval(60), dueDate: now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [undated, dated], area: work, now: now)

        #expect(vm.undatedTasks.map(\.safeTitle) == ["No date"])
        #expect(vm.datedSections.flatMap { $0.tasks.map(\.safeTitle) } == ["Dated"])
    }

    /// A bucket with nothing in it produces no header at all.
    @Test func dropsEmptyBuckets() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let today = insertTask("Today only", into: inbox, createdAt: now, dueDate: now, in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [today], area: work, now: now)

        #expect(vm.datedSections.map(\.segment) == [.today])
    }

    // MARK: - Scope

    /// Home opens on the Planned half; both pools are always derived so switching is free.
    @Test func defaultsToPlannedScopeAndSwitchesFree() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let inbox = insertList("Inbox", into: work, order: "m", in: context)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let dated = insertTask("Dated", into: inbox, createdAt: now, dueDate: now, in: context)
        let undated = insertTask("Undated", into: inbox, createdAt: now.addingTimeInterval(60), in: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work], lists: [inbox], tasks: [dated, undated], area: work, now: now)

        #expect(vm.scope == .planned)
        #expect(vm.datedSections.flatMap { $0.tasks.map(\.safeTitle) } == ["Dated"])
        #expect(vm.undatedTasks.map(\.safeTitle) == ["Undated"])

        vm.selectScope(.unplanned)
        #expect(vm.scope == .unplanned)
        #expect(vm.datedSections.flatMap { $0.tasks.map(\.safeTitle) } == ["Dated"])
        #expect(vm.undatedTasks.map(\.safeTitle) == ["Undated"])
    }

    // MARK: - Degenerate input

    @Test func anAreaWithNoListsShowsNothing() throws {
        let context = try makeContext()
        let work = insertArea("Work", order: "a", into: context)
        let personal = insertArea("Personal", order: "b", into: context)
        try? context.save()

        let vm = HomeViewModel(modelContext: context)
        update(vm, groups: [work, personal], lists: [], tasks: [], area: work)

        #expect(vm.undatedTasks.isEmpty)
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

        #expect(vm.undatedTasks.map(\.safeTitle) == ["Filed"])
    }
}
