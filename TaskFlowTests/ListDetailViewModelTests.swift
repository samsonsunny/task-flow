import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct ListDetailViewModelTests {

    private func createViewModel(
        list: ReminderList,
        allTasks: [TaskItem],
        context: ModelContext
    ) -> ListDetailViewModel {
        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        vm.update(tasks: allTasks, lists: [list], allTasks: allTasks)
        return vm
    }

    // MARK: - assignSortOrder

    @Test func assignSortOrderPlacesAtEndOfExistingList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let existing = makeTasks(sortOrders: ["m", "t", "w"])
        existing.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: existing, context: context)
        let newTask = TaskItem(taskTitle: "New", dueDate: nil)
        context.insert(newTask)
        vm.assignSortOrder(for: newTask, in: list)

        #expect(newTask.sortOrder != nil)
        let all = existing + [newTask]
        let sorted = sortedBySortOrder(all)
        #expect(sorted.last?.taskTitle == "New")
        assertValidTaskSortOrders(all)
    }

    @Test func assignSortOrderForSingleItemList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let existing = makeTasks(sortOrders: ["m"])
        existing.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: existing, context: context)
        let newTask = TaskItem(taskTitle: "New", dueDate: nil)
        context.insert(newTask)
        vm.assignSortOrder(for: newTask, in: list)

        let sortOrder = try #require(newTask.sortOrder)
        #expect(sortOrder > "m")
    }

    @Test func assignSortOrderForFirstTaskInEmptyList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let vm = createViewModel(list: list, allTasks: [], context: context)
        let task = TaskItem(taskTitle: "First", dueDate: nil)
        task.reminderList = list
        context.insert(task)
        vm.assignSortOrder(for: task, in: list)

        #expect(task.sortOrder == "m")
    }

    // MARK: - moveTasks

    @Test func moveFirstTaskToLastPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 4)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 1", "Task 2", "Task 3", "Task 0"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveLastTaskToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 3), toOffset: 0)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 3", "Task 0", "Task 1", "Task 2"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveFirstTaskToSecondPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 1)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 1", "Task 0", "Task 2", "Task 3"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveSecondTaskToThirdPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 2)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 0", "Task 2", "Task 1", "Task 3"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveSecondTaskToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 0)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 1", "Task 0", "Task 2", "Task 3"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveFirstTaskToSecondToLastPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 1", "Task 2", "Task 3", "Task 0"])
        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    @Test func moveTaskToSameIndexIsNoOp() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let beforeOrders = tasks.map { $0.sortOrder }
        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 1)

        let afterOrders = tasks.map { $0.sortOrder }
        #expect(beforeOrders == afterOrders)
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveMultipleNonAdjacentItems() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet([0, 2]), toOffset: 4)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 1", "Task 3", "Task 0", "Task 2"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveAdjacentItemsDoesNotCrash() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "e", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet([2, 3]), toOffset: 0)

        assertValidTaskSortOrders(tasks)
    }

    @Test func moveTasksMidpointExhaustionTriggersWiden() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["f", "fa"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let newTask = TaskItem(taskTitle: "Inserted", dueDate: nil)
        newTask.reminderList = list
        context.insert(newTask)
        try? context.save()

        let allTasks = tasks + [newTask]
        let vm = createViewModel(list: list, allTasks: allTasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 1)

        assertValidTaskSortOrders(allTasks)
        let sorted = sortedBySortOrder(allTasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 0", "Inserted", "Task 1"])
    }

    // MARK: - handleDrop

    @Test func dropOnUpperZoneReordersAmongSiblings() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[2].taskId
        vm.handleDrop(target: tasks[1], location: CGPoint(x: 0, y: 10))

        assertValidTaskSortOrders(tasks)
        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 0", "Task 2", "Task 1"])
        #expect(sorted[1].parentTask == nil)
        #expect(sorted[2].parentTask == nil)
    }

    @Test func dropOnLowerZoneMakesChild() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[2].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        #expect(tasks[2].parentTask?.persistentModelID == tasks[0].persistentModelID)
        assertValidTaskSortOrders(tasks)
    }

    @Test func dropTaskOnItselfIsNoOp() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[0].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        #expect(tasks[0].parentTask == nil)
        #expect(tasks[0].sortOrder == "a")
    }

    @Test func dropParentOnDescendantIsRejected() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        tasks[1].parentTask = tasks[0]
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[0].taskId
        vm.handleDrop(target: tasks[1], location: CGPoint(x: 0, y: 30))

        #expect(tasks[1].parentTask?.persistentModelID == tasks[0].persistentModelID)
    }

    @Test func dropIntoTaskWithExistingSubtasks() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        tasks[1].parentTask = tasks[0]
        tasks[2].parentTask = tasks[0]
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[3].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        #expect(tasks[3].parentTask?.persistentModelID == tasks[0].persistentModelID)
        let children = tasks[0].subtasks.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        #expect(children.count == 3)
        assertValidTaskSortOrders(Array(tasks[0].subtasks))
    }

    @Test func dropIntoTaskWithNoSubtasks() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[1].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        #expect(tasks[1].parentTask?.persistentModelID == tasks[0].persistentModelID)
        #expect(tasks[0].subtasks.count == 1)
    }

    // MARK: - moveTaskToRoot

    @Test func moveNestedTaskToEmptyRoot() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        let nested = TaskItem(taskTitle: "Nested", dueDate: nil)
        nested.sortOrder = "a"
        nested.parentTask = tasks[0]
        nested.reminderList = list
        context.insert(nested)
        try? context.save()

        let allTasks = tasks + [nested]
        let vm = createViewModel(list: list, allTasks: allTasks, context: context)
        vm.draggedTaskId = nested.taskId
        vm.moveTaskToRoot()

        #expect(nested.parentTask == nil)
        #expect(nested.sortOrder != nil)
        assertValidTaskSortOrders(allTasks)
    }

    @Test func moveNestedTaskToRootWithExistingSiblings() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "t"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        let nested = TaskItem(taskTitle: "Nested", dueDate: nil)
        nested.sortOrder = "m"
        nested.parentTask = tasks[0]
        nested.reminderList = list
        context.insert(nested)
        try? context.save()

        let allTasks = tasks + [nested]
        let vm = createViewModel(list: list, allTasks: allTasks, context: context)
        vm.draggedTaskId = nested.taskId
        vm.moveTaskToRoot()

        #expect(nested.parentTask == nil)
        let rootTasks = allTasks.filter { $0.parentTask == nil }
        assertValidTaskSortOrders(rootTasks)
        let sorted = sortedBySortOrder(rootTasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 0", "Nested", "Task 1"])
    }

    // MARK: - isDescendant

    @Test func isDescendantDirectParent() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let parent = TaskItem(taskTitle: "Parent", dueDate: nil)
        let child = TaskItem(taskTitle: "Child", dueDate: nil)
        child.parentTask = parent
        context.insert(parent)
        context.insert(child)
        try? context.save()

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        #expect(vm.isDescendant(child, of: parent))
    }

    @Test func isDescendantGrandparent() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let grandparent = TaskItem(taskTitle: "GP", dueDate: nil)
        let parent = TaskItem(taskTitle: "Parent", dueDate: nil)
        let child = TaskItem(taskTitle: "Child", dueDate: nil)
        parent.parentTask = grandparent
        child.parentTask = parent
        context.insert(grandparent)
        context.insert(parent)
        context.insert(child)
        try? context.save()

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        #expect(vm.isDescendant(child, of: grandparent))
    }

    @Test func isDescendantUnrelatedReturnsFalse() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let taskA = TaskItem(taskTitle: "A", dueDate: nil)
        let taskB = TaskItem(taskTitle: "B", dueDate: nil)
        context.insert(taskA)
        context.insert(taskB)
        try? context.save()

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        #expect(!vm.isDescendant(taskA, of: taskB))
    }

    @Test func isDescendantSelfReturnsFalse() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let task = TaskItem(taskTitle: "Self", dueDate: nil)
        context.insert(task)
        try? context.save()

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        #expect(!vm.isDescendant(task, of: task))
    }

    // MARK: - commitQuickCapture

    @Test func quickCaptureAssignsSortOrderInNonEmptyList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let existing = makeTasks(sortOrders: ["a", "m"])
        existing.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: existing, context: context)
        vm.update(tasks: existing, lists: [list], allTasks: existing)
        vm.commitQuickCapture(text: "Quick", in: list.persistentModelID)

        let allTasks = existing + (try! context.fetch(FetchDescriptor<TaskItem>()).filter { $0.taskTitle == "Quick" })
        let newTask = try #require(allTasks.first { $0.taskTitle == "Quick" })
        #expect(newTask.sortOrder != nil)
        assertValidTaskSortOrders(allTasks)
        let sorted = sortedBySortOrder(allTasks)
        #expect(sorted.last?.taskTitle == "Quick")
    }

    @Test func quickCaptureAssignsSortOrderInEmptyList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let vm = createViewModel(list: list, allTasks: [], context: context)
        vm.update(tasks: [], lists: [list], allTasks: [])
        vm.commitQuickCapture(text: "First", in: list.persistentModelID)

        let quickTasks = try! context.fetch(FetchDescriptor<TaskItem>()).filter { $0.taskTitle == "First" }
        #expect(quickTasks.count == 1)
        #expect(quickTasks[0].sortOrder != nil)
    }

    @Test func quickCaptureSetsLastAddedTaskID() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let vm = createViewModel(list: list, allTasks: [], context: context)
        vm.update(tasks: [], lists: [list], allTasks: [])
        vm.commitQuickCapture(text: "Quick", in: list.persistentModelID)

        let createdTasks = try! context.fetch(FetchDescriptor<TaskItem>()).filter { $0.taskTitle == "Quick" }
        #expect(createdTasks.count == 1)
        #expect(vm.lastAddedTaskID == createdTasks[0].persistentModelID)
    }

    // MARK: - Property-based invariants

    @Test func chainOfReordersAtSamePositionPreservesInvariants() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        var tasks = makeTasks(sortOrders: ["a", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        for i in 0..<10 {
            let newTask = TaskItem(taskTitle: "Insert \(i)", dueDate: nil)
            newTask.sortOrder = nil
            newTask.reminderList = list
            context.insert(newTask)
            tasks.append(newTask)
            try? context.save()

            let vm = createViewModel(list: list, allTasks: tasks, context: context)
            vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 2)
            assertValidTaskSortOrders(tasks)
        }
    }

    @Test func crossListMoveAndReorderPreservesInvariants() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let listA = ReminderList(name: "A")
        let listB = ReminderList(name: "B")
        context.insert(listA)
        context.insert(listB)
        let tasksA = makeTasks(sortOrders: ["a", "m"])
        tasksA.forEach { $0.reminderList = listA; context.insert($0) }
        let tasksB = makeTasks(sortOrders: ["t"])
        tasksB.forEach { $0.reminderList = listB; context.insert($0) }
        try? context.save()

        let allTasks = tasksA + tasksB
        let vm = createViewModel(list: listA, allTasks: allTasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 0)

        assertValidTaskSortOrders(tasksA)
    }
}
