import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct ReminderSegmentViewModelTests {
    let container: ModelContainer
    let context: ModelContext
    let now: Date
    let calendar: Calendar

    init() {
        container = TaskPreviewData.container()
        context = container.mainContext
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
        now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
    }

    private func makeTask(title: String, date: Date?, parent: TaskItem? = nil) -> TaskItem {
        let task = TaskItem(taskTitle: title, dueDate: date)
        task.parentTask = parent
        task.createdAt = now
        context.insert(task)
        return task
    }

    private func makeVM(segment: ReminderSegment) -> ReminderSegmentViewModel {
        let vm = ReminderSegmentViewModel(modelContext: context, segment: segment)
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = (try? context.fetch(descriptor)) ?? []
        vm.update(tasks: allTasks, lists: [], now: now)
        return vm
    }

    // MARK: - Rule 1: Undated subtasks stay in detail; dated subtasks surface flat at depth 0

    @Test func parentShowsWithOverview_UndatedChildHidden() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: nil, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 1)
        #expect(vm.flatNodes[0].task.safeTitle == "Parent")
        #expect(vm.flatNodes[0].depth == 0)
        #expect(vm.flatNodes[0].subtaskSummary.total == 1)
        #expect(vm.flatNodes[0].subtaskSummary.pending == 1)
    }

    @Test func datedChildSurfacesFlatInItsOwnSegment() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: tomorrow, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        #expect(todayVM.flatNodes.count == 1)
        #expect(todayVM.flatNodes[0].task.safeTitle == "Parent")

        let tomorrowVM = makeVM(segment: .tomorrow)
        #expect(tomorrowVM.flatNodes.count == 1)
        #expect(tomorrowVM.flatNodes[0].task.safeTitle == "Child")
        #expect(tomorrowVM.flatNodes[0].depth == 0)
    }

    @Test func childWithoutDateNotShownInTimeline() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: nil, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 1)
        #expect(vm.flatNodes[0].task.safeTitle == "Parent")
        #expect(vm.flatNodes[0].subtaskSummary.total == 1)
        #expect(vm.flatNodes[0].subtaskSummary.pending == 1)
    }

    // MARK: - Rule 2: Top-level tasks and dated subtasks

    @Test func childDueToday_ParentNoDate_OrphanStandalone() {
        let child = makeTask(title: "Child", date: now)

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 1)
        #expect(vm.flatNodes[0].task.safeTitle == "Child")
        #expect(vm.flatNodes[0].depth == 0)
    }

    @Test func childDueToday_ParentDueTomorrow_BothSurfaceInTheirOwnSegments() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let parent = makeTask(title: "Parent", date: tomorrow)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        #expect(todayVM.flatNodes.count == 1)
        #expect(todayVM.flatNodes[0].task.safeTitle == "Child")

        let tomorrowVM = makeVM(segment: .tomorrow)
        #expect(tomorrowVM.flatNodes.count == 1)
        #expect(tomorrowVM.flatNodes[0].task.safeTitle == "Parent")
    }

    // MARK: - Dedup

    @Test func dedup_BothSurfaceOnce_WhenBothAreDated() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 2)
        #expect(vm.flatNodes.map(\.task.safeTitle).filter { $0 == "Parent" }.count == 1)
        #expect(vm.flatNodes.map(\.task.safeTitle).filter { $0 == "Child" }.count == 1)
    }

    // MARK: - Dated subtasks surface in upcoming and overdue

    @Test func datedSubtaskSurfacesInUpcomingDaySections() {
        let upcomingDate = calendar.date(byAdding: .day, value: 3, to: now)!
        let parent = makeTask(title: "Parent", date: nil)
        let child = makeTask(title: "Child", date: upcomingDate, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .upcoming)
        let nodes = vm.flatNodes(for: [parent, child])
        #expect(nodes.count == 1)
        #expect(nodes[0].task.safeTitle == "Child")
        #expect(nodes[0].depth == 0)
    }

    @Test func undatedSubtaskExcludedFromUpcomingDaySections() {
        let upcomingDate = calendar.date(byAdding: .day, value: 3, to: now)!
        let parent = makeTask(title: "Parent", date: upcomingDate)
        let child = makeTask(title: "Child", date: nil, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .upcoming)
        let nodes = vm.flatNodes(for: [parent, child])
        #expect(nodes.count == 1)
        #expect(nodes[0].task.safeTitle == "Parent")
    }

    // MARK: - Collapse no longer affects display

    @Test func collapseHasNoEffectOnFlatDisplay() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = (try? context.fetch(descriptor)) ?? []
        vm.update(tasks: allTasks, lists: [], now: now)
        #expect(vm.flatNodes.count == 1)
        vm.update(tasks: allTasks, lists: [], now: now)
        #expect(vm.flatNodes.count == 1)
    }

    // MARK: - Overdue

    @Test func overdueDatedSubtaskSurfacesInOverdueDisplay() {
        let overdueDate = calendar.date(byAdding: .day, value: -1, to: now)!
        let parent = makeTask(title: "Parent", date: overdueDate)
        let child = makeTask(title: "Child", date: overdueDate, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .overdue)
        #expect(vm.overdueDisplayTasks.count == 2)
        #expect(vm.overdueDisplayTasks.map(\.safeTitle).contains("Parent"))
        #expect(vm.overdueDisplayTasks.map(\.safeTitle).contains("Child"))
    }

    @Test func overdueUndatedSubtaskStaysHidden() {
        let overdueDate = calendar.date(byAdding: .day, value: -1, to: now)!
        let parent = makeTask(title: "Parent", date: overdueDate)
        let child = makeTask(title: "Child", date: nil, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .overdue)
        #expect(vm.overdueDisplayTasks.count == 1)
        #expect(vm.overdueDisplayTasks[0].safeTitle == "Parent")
    }

    // MARK: - Refresh / Time advancement

    @Test func refreshNowAdvancesStoredNow() {
        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        let past = calendar.date(byAdding: .hour, value: -1, to: now)!
        vm.update(tasks: [], lists: [], now: past)
        #expect(vm.now == past)

        vm.refreshNow()

        #expect(vm.now >= now)
    }

    @Test func overdueTasksUpdatesWhenNowAdvances() {
        let earlyNow = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 10))!
        let lateNow = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 11))!
        let dueAt1030 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 10, minute: 30))!

        let task = makeTask(title: "Task", date: dueAt1030)

        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = (try? context.fetch(descriptor)) ?? []

        let vm = ReminderSegmentViewModel(modelContext: context, segment: .today)
        vm.update(tasks: allTasks, lists: [], now: earlyNow)
        #expect(vm.overdueTasks.isEmpty, "Task due at 10:30 should not be overdue at 10:00")

        vm.update(tasks: allTasks, lists: [], now: lateNow)
        #expect(vm.overdueTasks.count == 1, "Task due at 10:30 should be overdue at 11:00")
        #expect(vm.overdueTasks[0].safeTitle == "Task")
    }

    // MARK: - Swipe reschedule

    @Test func rescheduleToNextDay_setsDueDateToNextCalendarDayStart() {
        let task = makeTask(title: "Push me", date: now)
        let vm = makeVM(segment: .today)

        vm.rescheduleToNextDay(task)

        let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        #expect(task.dueDate == expectedNextDay, "Task due date should be start of next day")
    }

    @Test func rescheduleToNextDay_persistsAfterSave() {
        let task = makeTask(title: "Persist", date: now)
        let vm = makeVM(segment: .today)

        vm.rescheduleToNextDay(task)

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.taskTitle == "Persist" }
        )
        let fetched = try? context.fetch(descriptor).first
        #expect(fetched != nil)
        let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        #expect(fetched?.dueDate == expectedNextDay)
    }
}
