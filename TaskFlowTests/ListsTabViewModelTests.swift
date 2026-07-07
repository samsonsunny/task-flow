import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct ListsTabViewModelTests {

    private func createViewModel(
        lists: [ReminderList],
        groups: [ReminderListGroup],
        allTasks: [TaskItem],
        context: ModelContext
    ) -> ListsTabViewModel {
        let vm = ListsTabViewModel(modelContext: context)
        vm.update(lists: lists, groups: groups, allTasks: allTasks)
        return vm
    }

    @Test func moveFirstListToLastPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group")
        context.insert(group)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = group; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 4, in: lists, group: group)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 1", "List 2", "List 3", "List 0"])
        assertValidListSortOrders(lists)
    }

    @Test func moveLastListToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group")
        context.insert(group)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = group; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 3), toOffset: 0, in: lists, group: group)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 3", "List 0", "List 1", "List 2"])
        assertValidListSortOrders(lists)
    }

    @Test func moveFirstListToSecondPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group")
        context.insert(group)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = group; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 1, in: lists, group: group)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 1", "List 0", "List 2", "List 3"])
        assertValidListSortOrders(lists)
    }

    @Test func moveSecondListToThirdPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group")
        context.insert(group)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = group; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 1), toOffset: 2, in: lists, group: group)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 0", "List 2", "List 1", "List 3"])
        assertValidListSortOrders(lists)
    }

    @Test func moveSecondListToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group")
        context.insert(group)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = group; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 1), toOffset: 0, in: lists, group: group)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 1", "List 0", "List 2", "List 3"])
        assertValidListSortOrders(lists)
    }

    @Test func moveListToSameIndexIsNoOp() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group")
        context.insert(group)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = group; context.insert($0) }
        try? context.save()

        let beforeOrders = lists.map { $0.sortOrder }
        let vm = createViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 1), toOffset: 1, in: lists, group: group)

        let afterOrders = lists.map { $0.sortOrder }
        #expect(beforeOrders == afterOrders)
        assertValidListSortOrders(lists)
    }

    @Test func moveListWithinSameGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group A")
        context.insert(group)
        let lists = [
            ReminderList(name: "Alpha"),
            ReminderList(name: "Beta"),
            ReminderList(name: "Gamma")
        ]
        lists.forEach { $0.group = group; $0.sortOrder = ["a", "m", "t"][lists.firstIndex(of: $0)!]; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 2), toOffset: 0, in: lists, group: group)

        for list in lists {
            #expect(list.group?.persistentModelID == group.persistentModelID)
        }
        assertValidListSortOrders(lists)
    }

    @Test func moveListToDifferentGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let groupA = ReminderListGroup(name: "Group A")
        let groupB = ReminderListGroup(name: "Group B")
        context.insert(groupA)
        context.insert(groupB)
        let list = ReminderList(name: "Moveable")
        list.sortOrder = "m"
        list.group = groupA
        context.insert(list)
        let existingInB = ReminderList(name: "Existing B")
        existingInB.sortOrder = "a"
        existingInB.group = groupB
        context.insert(existingInB)
        try? context.save()

        let vm = createViewModel(lists: [list, existingInB], groups: [groupA, groupB], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 1, in: [list], group: groupB)

        #expect(list.group?.persistentModelID == groupB.persistentModelID)
    }

    @Test func moveListToEmptyGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Empty Group")
        context.insert(group)
        let list = ReminderList(name: "Solo")
        list.sortOrder = "m"
        context.insert(list)
        try? context.save()

        let vm = createViewModel(lists: [list], groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 0, in: [list], group: group)

        #expect(list.group?.persistentModelID == group.persistentModelID)
        #expect(list.sortOrder != nil)
    }

    // MARK: - List & Group Creation Tests

    @Test func createListWithoutGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        try? context.save()

        let vm = createViewModel(lists: [], groups: [], allTasks: [], context: context)

        let descriptor = FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.name)])
        #expect((try? context.fetch(descriptor))?.isEmpty == true)

        vm.createList(name: "Shopping")

        let lists = try? context.fetch(descriptor)
        #expect(lists?.count == 1)
        #expect(lists?.first?.name == "Shopping")
        #expect(lists?.first?.group == nil)
    }

    @Test func createListWithGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Home")
        context.insert(group)
        try? context.save()

        let vm = createViewModel(lists: [], groups: [group], allTasks: [], context: context)
        vm.createList(name: "Groceries", group: group)

        let descriptor = FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.name)])
        let lists = try? context.fetch(descriptor)
        #expect(lists?.count == 1)
        #expect(lists?.first?.name == "Groceries")
        #expect(lists?.first?.group?.persistentModelID == group.persistentModelID)
    }

    @Test func createGroupWithoutList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        try? context.save()

        let vm = createViewModel(lists: [], groups: [], allTasks: [], context: context)

        let descriptor = FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.name)])
        #expect((try? context.fetch(descriptor))?.isEmpty == true)

        vm.createGroup(name: "Work", sourceList: nil)

        let groups = try? context.fetch(descriptor)
        #expect(groups?.count == 1)
        #expect(groups?.first?.name == "Work")
    }

    @Test func createGroupWithList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Tasks")
        list.sortOrder = "m"
        context.insert(list)
        try? context.save()

        let vm = createViewModel(lists: [list], groups: [], allTasks: [], context: context)
        vm.createGroup(name: "Projects", sourceList: list)

        let groupDescriptor = FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.name)])
        let groups = try? context.fetch(groupDescriptor)
        #expect(groups?.count == 1)
        #expect(groups?.first?.name == "Projects")
        #expect(list.group?.persistentModelID == groups?.first?.persistentModelID)
    }

    @Test func createListRespectsSortOrder() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        try? context.save()

        let vm = createViewModel(lists: [], groups: [], allTasks: [], context: context)

        vm.createList(name: "First")
        vm.createList(name: "Second")
        vm.createList(name: "Third")

        let descriptor = FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.name)])
        let lists = try? context.fetch(descriptor)
        #expect(lists?.count == 3)
        for list in lists ?? [] {
            #expect(list.sortOrder != nil)
        }
        let orders = lists?.compactMap { $0.sortOrder } ?? []
        #expect(Set(orders).count == orders.count, "sortOrders should be unique")
    }

    @Test func createGroupRespectsSortOrder() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        try? context.save()

        let vm = createViewModel(lists: [], groups: [], allTasks: [], context: context)

        vm.createGroup(name: "Alpha", sourceList: nil)
        vm.createGroup(name: "Beta", sourceList: nil)
        vm.createGroup(name: "Gamma", sourceList: nil)

        let descriptor = FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.name)])
        let groups = try? context.fetch(descriptor)
        #expect(groups?.count == 3)
        for group in groups ?? [] {
            #expect(group.sortOrder != nil)
        }
        let orders = groups?.compactMap { $0.sortOrder } ?? []
        #expect(Set(orders).count == orders.count, "sortOrders should be unique")
    }
}
