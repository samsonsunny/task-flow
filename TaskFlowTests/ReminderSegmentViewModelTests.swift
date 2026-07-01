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

    // MARK: - Rule 1: Parent-driven display

    @Test func parentDueToday_ChildDueToday_BothInline() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 2)
        #expect(vm.flatNodes[0].task.safeTitle == "Parent")
        #expect(vm.flatNodes[0].depth == 0)
        #expect(vm.flatNodes[1].task.safeTitle == "Child")
        #expect(vm.flatNodes[1].depth == 1)
    }

    @Test func parentDueToday_ChildDueTomorrow_BothInlineInToday() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: tomorrow, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        #expect(todayVM.flatNodes.count == 2)
        #expect(todayVM.flatNodes[1].task.safeTitle == "Child")
        #expect(todayVM.flatNodes[1].depth == 1)
    }

    @Test func parentDueToday_ChildNoDate_ChildVisibleInToday() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: nil, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 2)
        #expect(vm.flatNodes[1].task.safeTitle == "Child")
    }

    // MARK: - Rule 2: Orphan subtasks

    @Test func childDueToday_ParentNoDate_OrphanStandalone() {
        let child = makeTask(title: "Child", date: now)

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 1)
        #expect(vm.flatNodes[0].task.safeTitle == "Child")
        #expect(vm.flatNodes[0].depth == 0)
    }

    @Test func childDueToday_ParentDueTomorrow_OrphanInToday_InlineInTomorrow() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let parent = makeTask(title: "Parent", date: tomorrow)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        #expect(todayVM.flatNodes.count == 1)
        #expect(todayVM.flatNodes[0].task.safeTitle == "Child")
        #expect(todayVM.flatNodes[0].depth == 0)

        let tomorrowVM = makeVM(segment: .tomorrow)
        #expect(tomorrowVM.flatNodes.count == 2)
        #expect(tomorrowVM.flatNodes[0].task.safeTitle == "Parent")
        #expect(tomorrowVM.flatNodes[1].task.safeTitle == "Child")
    }

    // MARK: - Dedup

    @Test func dedup_ChildNotDuplicatedWhenUnderParent() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        #expect(vm.flatNodes.count == 2)
    }

    // MARK: - Collapse / Expand

    @Test func collapseHidesChildren() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        vm.toggleCollapse(parent)
        #expect(vm.flatNodes.count == 1)
        #expect(vm.flatNodes[0].task.safeTitle == "Parent")
    }

    @Test func expandShowsChildren() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        vm.toggleCollapse(parent)
        #expect(vm.flatNodes.count == 1)
        vm.toggleCollapse(parent)
        #expect(vm.flatNodes.count == 2)
    }

    @Test func collapseStateIsPerViewModelInstance() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        todayVM.toggleCollapse(parent)
        #expect(todayVM.flatNodes.count == 1)

        let todayVM2 = makeVM(segment: .today)
        #expect(todayVM2.flatNodes.count == 2)
    }
}
