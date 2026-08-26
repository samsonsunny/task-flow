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
        let existing = makeTasks(sortOrders: [0, 1, 2])
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
        let existing = makeTasks(sortOrders: [5])
        existing.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: existing, context: context)
        let newTask = TaskItem(taskTitle: "New", dueDate: nil)
        context.insert(newTask)
        vm.assignSortOrder(for: newTask, in: list)

        let sortOrder = try #require(newTask.sortOrder)
        #expect(sortOrder > 5)
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

        #expect(task.sortOrder == 0)
    }

    // MARK: - moveTasks

    @Test func moveFirstTaskToLastPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
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
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
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
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 1)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 0", "Task 1", "Task 2", "Task 3"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveSecondTaskToThirdPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 2)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 0", "Task 1", "Task 2", "Task 3"])
        assertValidTaskSortOrders(tasks)
    }

    @Test func moveSecondTaskToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
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
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        let sorted = sortedBySortOrder(tasks)
        #expect(sorted.map { $0.taskTitle } == ["Task 1", "Task 2", "Task 0", "Task 3"])
        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    @Test func moveTaskToSameIndexIsNoOp() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
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
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3])
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
        let tasks = makeTasks(sortOrders: [0, 1, 2, 3, 4])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet([2, 3]), toOffset: 0)

        assertValidTaskSortOrders(tasks)
    }

    @Test func moveTaskPreservesIntegerSortOrders() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: [0, 1])
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

    // MARK: - isDescendant (disabled — method removed with drop reparenting)

    // @Test func isDescendantDirectParent() throws { ... }
    // @Test func isDescendantGrandparent() throws { ... }
    // @Test func isDescendantUnrelatedReturnsFalse() throws { ... }
    // @Test func isDescendantSelfReturnsFalse() throws { ... }

    // MARK: - commitQuickCapture

    @Test func quickCaptureAssignsSortOrderInNonEmptyList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let existing = makeTasks(sortOrders: [0, 1])
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
        var tasks = makeTasks(sortOrders: [0, 1])
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
        let tasksA = makeTasks(sortOrders: [0, 1])
        tasksA.forEach { $0.reminderList = listA; context.insert($0) }
        let tasksB = makeTasks(sortOrders: [0])
        tasksB.forEach { $0.reminderList = listB; context.insert($0) }
        try? context.save()

        let allTasks = tasksA + tasksB
        let vm = createViewModel(list: listA, allTasks: allTasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 0)

        assertValidTaskSortOrders(tasksA)
    }
}
