import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct EditorSubtaskTests {
    let container: ModelContainer
    let context: ModelContext

    init() {
        container = TaskPreviewData.container()
        context = container.mainContext
    }

    private func makeParent(title: String, list: ReminderList) -> TaskItem {
        let parent = TaskItem(taskTitle: title, dueDate: nil)
        parent.reminderList = list
        context.insert(parent)
        return parent
    }

    private func makeSubtask(title: String, order: String, parent: TaskItem) -> TaskItem {
        let subtask = TaskItem(taskTitle: title, dueDate: nil)
        subtask.parentTask = parent
        subtask.sortOrder = order
        context.insert(subtask)
        return subtask
    }

    private func makeVM(task: TaskItem) -> ReminderEditorViewModel {
        ReminderEditorViewModel(modelContext: context, task: task)
    }

    private func titles(_ vm: ReminderEditorViewModel, of parent: TaskItem) -> [String] {
        vm.subtasks(of: parent).map { $0.safeTitle }
    }

    // MARK: - Move Up / Move Down

    @Test func moveSubtaskUp_swapsWithPreviousSibling() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let parent = makeParent(title: "Parent", list: list)
        let x = makeSubtask(title: "X", order: "a", parent: parent)
        let y = makeSubtask(title: "Y", order: "m", parent: parent)
        _ = makeSubtask(title: "Z", order: "z", parent: parent)
        let vm = makeVM(task: parent)

        vm.moveSubtaskUp(y)

        #expect(titles(vm, of: parent) == ["Y", "X", "Z"])
        #expect(x.persistentModelID != y.persistentModelID)
    }

    @Test func moveSubtaskDown_swapsWithNextSibling() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let parent = makeParent(title: "Parent", list: list)
        let x = makeSubtask(title: "X", order: "a", parent: parent)
        _ = makeSubtask(title: "Y", order: "m", parent: parent)
        _ = makeSubtask(title: "Z", order: "z", parent: parent)
        let vm = makeVM(task: parent)

        vm.moveSubtaskDown(x)

        #expect(titles(vm, of: parent) == ["Y", "X", "Z"])
    }

    @Test func moveSubtaskUp_firstSibling_isNoOp() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let parent = makeParent(title: "Parent", list: list)
        let x = makeSubtask(title: "X", order: "a", parent: parent)
        _ = makeSubtask(title: "Y", order: "m", parent: parent)
        let vm = makeVM(task: parent)

        vm.moveSubtaskUp(x)

        #expect(titles(vm, of: parent) == ["X", "Y"])
    }

    @Test func moveSubtaskDown_lastSibling_isNoOp() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let parent = makeParent(title: "Parent", list: list)
        _ = makeSubtask(title: "X", order: "a", parent: parent)
        let y = makeSubtask(title: "Y", order: "m", parent: parent)
        let vm = makeVM(task: parent)

        vm.moveSubtaskDown(y)

        #expect(titles(vm, of: parent) == ["X", "Y"])
    }

    @Test func canMove_returnsFalseForSingleSibling() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let parent = makeParent(title: "Parent", list: list)
        let solo = makeSubtask(title: "Solo", order: "m", parent: parent)
        let vm = makeVM(task: parent)

        #expect(vm.canMoveSubtaskUp(solo) == false)
        #expect(vm.canMoveSubtaskDown(solo) == false)
    }

    @Test func canMove_boundariesForOrderedSiblings() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let parent = makeParent(title: "Parent", list: list)
        let x = makeSubtask(title: "X", order: "a", parent: parent)
        _ = makeSubtask(title: "Y", order: "m", parent: parent)
        let z = makeSubtask(title: "Z", order: "z", parent: parent)
        let vm = makeVM(task: parent)

        #expect(vm.canMoveSubtaskUp(x) == false)
        #expect(vm.canMoveSubtaskDown(x) == true)
        #expect(vm.canMoveSubtaskUp(z) == true)
        #expect(vm.canMoveSubtaskDown(z) == false)
    }

    // MARK: - Move to List

    @Test func moveSubtaskToOtherList_promotesToRootInDestination() {
        let listA = ReminderList(name: "A")
        let listB = ReminderList(name: "B")
        context.insert(listA)
        context.insert(listB)
        let parent = makeParent(title: "Parent", list: listA)
        let subtask = makeSubtask(title: "Sub", order: "m", parent: parent)
        let vm = makeVM(task: parent)

        vm.moveSubtask(subtask, to: listB)

        #expect(subtask.parentTask == nil)
        #expect(subtask.reminderList?.persistentModelID == listB.persistentModelID)
        #expect(titles(vm, of: parent).contains("Sub") == false)
        #expect(subtask.sortOrder != nil)
    }

    @Test func moveSubtaskToOwnList_promotesInPlace() {
        let listA = ReminderList(name: "A")
        context.insert(listA)
        let parent = makeParent(title: "Parent", list: listA)
        let subtask = makeSubtask(title: "Sub", order: "m", parent: parent)
        let vm = makeVM(task: parent)

        vm.moveSubtask(subtask, to: listA)

        #expect(subtask.parentTask == nil)
        #expect(subtask.reminderList?.persistentModelID == listA.persistentModelID)
        #expect(titles(vm, of: parent).isEmpty)
    }

    @Test func moveSubtaskAssignsSortOrderAfterExistingTasks() throws {
        let listA = ReminderList(name: "A")
        let listB = ReminderList(name: "B")
        context.insert(listA)
        context.insert(listB)
        let parent = makeParent(title: "Parent", list: listA)
        let subtask = makeSubtask(title: "Sub", order: "m", parent: parent)

        let existing = TaskItem(taskTitle: "Existing", dueDate: nil)
        existing.reminderList = listB
        existing.sortOrder = "m"
        context.insert(existing)

        let vm = makeVM(task: parent)
        vm.moveSubtask(subtask, to: listB)

        let order = try #require(subtask.sortOrder)
        #expect(order > "m")
    }
}
