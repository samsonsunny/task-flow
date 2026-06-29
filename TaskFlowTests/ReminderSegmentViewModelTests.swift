import XCTest
import SwiftData
@testable import TaskFlow

@MainActor
final class ReminderSegmentViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var now: Date!
    private var calendar: Calendar!

    override func setUp() {
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

    func testParentDueToday_ChildDueToday_BothInline() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        XCTAssertEqual(vm.flatNodes.count, 2)
        XCTAssertEqual(vm.flatNodes[0].task.safeTitle, "Parent")
        XCTAssertEqual(vm.flatNodes[0].depth, 0)
        XCTAssertEqual(vm.flatNodes[1].task.safeTitle, "Child")
        XCTAssertEqual(vm.flatNodes[1].depth, 1)
    }

    func testParentDueToday_ChildDueTomorrow_BothInlineInToday() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: tomorrow, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        XCTAssertEqual(todayVM.flatNodes.count, 2)
        XCTAssertEqual(todayVM.flatNodes[1].task.safeTitle, "Child")
        XCTAssertEqual(todayVM.flatNodes[1].depth, 1)
    }

    func testParentDueToday_ChildNoDate_ChildVisibleInToday() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: nil, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        XCTAssertEqual(vm.flatNodes.count, 2)
        XCTAssertEqual(vm.flatNodes[1].task.safeTitle, "Child")
    }

    // MARK: - Rule 2: Orphan subtasks

    func testChildDueToday_ParentNoDate_OrphanStandalone() {
        let child = makeTask(title: "Child", date: now)

        let vm = makeVM(segment: .today)
        XCTAssertEqual(vm.flatNodes.count, 1)
        XCTAssertEqual(vm.flatNodes[0].task.safeTitle, "Child")
        XCTAssertEqual(vm.flatNodes[0].depth, 0)
    }

    func testChildDueToday_ParentDueTomorrow_OrphanInToday_InlineInTomorrow() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let parent = makeTask(title: "Parent", date: tomorrow)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        XCTAssertEqual(todayVM.flatNodes.count, 1)
        XCTAssertEqual(todayVM.flatNodes[0].task.safeTitle, "Child")
        XCTAssertEqual(todayVM.flatNodes[0].depth, 0)

        let tomorrowVM = makeVM(segment: .tomorrow)
        XCTAssertEqual(tomorrowVM.flatNodes.count, 2)
        XCTAssertEqual(tomorrowVM.flatNodes[0].task.safeTitle, "Parent")
        XCTAssertEqual(tomorrowVM.flatNodes[1].task.safeTitle, "Child")
    }

    // MARK: - Dedup

    func testDedup_ChildNotDuplicatedWhenUnderParent() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        XCTAssertEqual(vm.flatNodes.count, 2)
    }

    // MARK: - Collapse / Expand

    func testCollapseHidesChildren() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        vm.toggleCollapse(parent)
        XCTAssertEqual(vm.flatNodes.count, 1)
        XCTAssertEqual(vm.flatNodes[0].task.safeTitle, "Parent")
    }

    func testExpandShowsChildren() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let vm = makeVM(segment: .today)
        vm.toggleCollapse(parent)
        XCTAssertEqual(vm.flatNodes.count, 1)
        vm.toggleCollapse(parent)
        XCTAssertEqual(vm.flatNodes.count, 2)
    }

    func testCollapseStateIsPerViewModelInstance() {
        let parent = makeTask(title: "Parent", date: now)
        let child = makeTask(title: "Child", date: now, parent: parent)
        parent.subtasks = [child]

        let todayVM = makeVM(segment: .today)
        todayVM.toggleCollapse(parent)
        XCTAssertEqual(todayVM.flatNodes.count, 1)

        let todayVM2 = makeVM(segment: .today)
        XCTAssertEqual(todayVM2.flatNodes.count, 2)
    }
}
