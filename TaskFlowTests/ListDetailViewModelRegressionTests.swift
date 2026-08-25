import Testing
import SwiftData
@testable import TaskFlow

@MainActor
struct ListDetailViewModelRegressionTests {
    var container: ModelContainer
    var context: ModelContext

    init() {
        container = TaskPreviewData.container()
        context = container.mainContext
    }

    @Test func flatNodesShowOnlyRootsWithSummaries() {
        let list = ReminderList(name: "Test")
        context.insert(list)

        let root = TaskItem(taskTitle: "Root", dueDate: nil)
        root.reminderList = list
        context.insert(root)

        let child1 = TaskItem(taskTitle: "Child 1")
        child1.parentTask = root
        child1.reminderList = list
        context.insert(child1)

        let child2 = TaskItem(taskTitle: "Child 2")
        child2.parentTask = root
        child2.reminderList = list
        context.insert(child2)

        let grandchild = TaskItem(taskTitle: "Grandchild")
        grandchild.parentTask = child1
        grandchild.reminderList = list
        context.insert(grandchild)

        root.subtasks = [child1, child2]
        child1.subtasks = [grandchild]

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        let allTasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        vm.update(tasks: allTasks, lists: [], allTasks: allTasks)

        #expect(vm.flatNodes.count == 4)
        #expect(vm.flatNodes[0].task.safeTitle == "Root")
        #expect(vm.flatNodes[0].depth == 0)
        #expect(vm.flatNodes[0].subtaskSummary.total == 2)
        #expect(vm.flatNodes[0].subtaskSummary.pending == 2)
        #expect(vm.flatNodes[0].subtaskSummary.completed == 0)
        #expect(vm.flatNodes[1].task.safeTitle == "Child 1")
        #expect(vm.flatNodes[1].depth == 1)
        #expect(vm.flatNodes[2].task.safeTitle == "Child 2")
        #expect(vm.flatNodes[2].depth == 1)
        #expect(vm.flatNodes[3].task.safeTitle == "Grandchild")
        #expect(vm.flatNodes[3].depth == 2)
    }

    @Test func collapseHidesSubtasks() {
        let list = ReminderList(name: "Test")
        context.insert(list)

        let root = TaskItem(taskTitle: "Root", dueDate: nil)
        root.reminderList = list
        context.insert(root)

        let child = TaskItem(taskTitle: "Child")
        child.parentTask = root
        child.reminderList = list
        context.insert(child)

        root.subtasks = [child]

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        let allTasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []

        vm.update(tasks: allTasks, lists: [], allTasks: allTasks)
        #expect(vm.flatNodes.count == 2)

        vm.toggleTaskCollapsed(root.taskId ?? "")
        #expect(vm.flatNodes.count == 1)
    }
}
