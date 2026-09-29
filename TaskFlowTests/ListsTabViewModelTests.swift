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

    private func area(_ name: String, order: String, context: ModelContext) -> ReminderListGroup {
        let group = ReminderListGroup(name: name, sortOrder: order)
        context.insert(group)
        return group
    }

    // MARK: - Reorder

    @Test func moveFirstListToLastPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = work; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [work], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 4, in: lists)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 1", "List 2", "List 3", "List 0"])
        assertValidListSortOrders(lists)
    }

    @Test func moveLastListToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = work; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [work], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 3), toOffset: 0, in: lists)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 3", "List 0", "List 1", "List 2"])
        assertValidListSortOrders(lists)
    }

    @Test func moveFirstListToSecondPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = work; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [work], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 1, in: lists)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 1", "List 0", "List 2", "List 3"])
        assertValidListSortOrders(lists)
    }

    @Test func moveSecondListToThirdPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = work; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [work], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 1), toOffset: 2, in: lists)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 0", "List 2", "List 1", "List 3"])
        assertValidListSortOrders(lists)
    }

    @Test func moveSecondListToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = work; context.insert($0) }
        try? context.save()

        let vm = createViewModel(lists: lists, groups: [work], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 1), toOffset: 0, in: lists)

        let sorted = sortedBySortOrder(lists)
        #expect(sorted.map { $0.name } == ["List 1", "List 0", "List 2", "List 3"])
        assertValidListSortOrders(lists)
    }

    @Test func moveListToSameIndexIsNoOp() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let lists = makeLists(sortOrders: ["a", "m", "t", "z"])
        lists.forEach { $0.group = work; context.insert($0) }
        try? context.save()

        let beforeOrders = lists.map { $0.sortOrder }
        let vm = createViewModel(lists: lists, groups: [work], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 1), toOffset: 1, in: lists)

        let afterOrders = lists.map { $0.sortOrder }
        #expect(beforeOrders == afterOrders)
        assertValidListSortOrders(lists)
    }

    // MARK: - Area scoping

    /// A list's area is fixed at creation, so reordering must never reparent it. A mixed
    /// batch is rejected outright rather than silently splitting across areas.
    @Test func reorderRejectsMixedAreas() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let personal = area("Personal", order: "b", context: context)
        let workList = ReminderList(name: "Work thing", sortOrder: "a", group: work)
        let personalList = ReminderList(name: "Personal thing", sortOrder: "m", group: personal)
        context.insert(workList)
        context.insert(personalList)
        try? context.save()

        let vm = createViewModel(
            lists: [workList, personalList], groups: [work, personal], allTasks: [], context: context
        )
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 2, in: [workList, personalList])

        #expect(workList.group?.persistentModelID == work.persistentModelID)
        #expect(personalList.group?.persistentModelID == personal.persistentModelID)
        #expect(workList.sortOrder == "a")
        #expect(personalList.sortOrder == "m")
    }

    @Test func createListLandsInNamedAreaOnly() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let personal = area("Personal", order: "b", context: context)
        try? context.save()

        let vm = createViewModel(lists: [], groups: [personal], allTasks: [], context: context)
        vm.createList(name: "Groceries", in: personal)

        let lists = (try? context.fetch(FetchDescriptor<ReminderList>())) ?? []
        #expect(lists.count == 1)
        #expect(lists.first?.name == "Groceries")
        #expect(lists.first?.group?.persistentModelID == personal.persistentModelID)
        #expect(lists.first?.sortOrder != nil)
    }

    /// Creation requires an area, so it must never seed one — seeding here is how a third
    /// area would appear.
    @Test func createListDoesNotSeedAreas() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        try? context.save()

        let vm = createViewModel(lists: [], groups: [work], allTasks: [], context: context)
        vm.createList(name: "Shopping", in: work)

        let groups = (try? context.fetch(FetchDescriptor<ReminderListGroup>())) ?? []
        #expect(groups.count == 1)
    }

    @Test func createListRejectsBlankName() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        try? context.save()

        let vm = createViewModel(lists: [], groups: [work], allTasks: [], context: context)
        #expect(vm.createList(name: "   ", in: work) == nil)
        #expect(((try? context.fetch(FetchDescriptor<ReminderList>())) ?? []).isEmpty)
    }

    @Test func createListRespectsSortOrder() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        try? context.save()

        let vm = createViewModel(lists: [], groups: [work], allTasks: [], context: context)
        vm.createList(name: "First", in: work)
        vm.createList(name: "Second", in: work)
        vm.createList(name: "Third", in: work)

        let lists = try? context.fetch(FetchDescriptor<ReminderList>(sortBy: [SortDescriptor(\.name)]))
        #expect(lists?.count == 3)
        for list in lists ?? [] {
            #expect(list.sortOrder != nil)
        }
        let orders = lists?.compactMap { $0.sortOrder } ?? []
        #expect(Set(orders).count == orders.count, "sortOrders should be unique")
    }

    @Test func orderedListsPinsBucketFirst() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let bucket = makeBucket(for: work, in: context)
        bucket.sortOrder = "z"
        let alpha = ReminderList(name: "Alpha", sortOrder: "a", group: work)
        let beta = ReminderList(name: "Beta", sortOrder: "m", group: work)
        context.insert(alpha)
        context.insert(beta)
        try? context.save()

        let vm = createViewModel(
            lists: [alpha, bucket, beta], groups: [work], allTasks: [], context: context
        )
        let ordered = vm.orderedLists(in: work)

        #expect(ordered.map { $0.persistentModelID } == [
            bucket.persistentModelID, alpha.persistentModelID, beta.persistentModelID
        ])
    }

    // MARK: - Bucket protection

    @Test func bucketCannotBeRenamed() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let bucket = makeBucket(for: work, in: context)
        let list = ReminderList(name: "Tasks", group: work)
        context.insert(list)
        try? context.save()

        let vm = createViewModel(lists: [bucket, list], groups: [work], allTasks: [], context: context)
        vm.renameList(bucket, to: "Renamed")

        #expect(bucket.name == "Inbox")
    }

    @Test func bucketCannotBeDeleted() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let bucket = makeBucket(for: work, in: context)
        let list = ReminderList(name: "Tasks", group: work)
        context.insert(list)
        try? context.save()
        let bucketID = bucket.persistentModelID

        let vm = createViewModel(lists: [bucket, list], groups: [work], allTasks: [], context: context)
        vm.deleteList(bucket, moveTasksTo: list)
        vm.deleteListAndTasks(bucket)

        let remaining = (try? context.fetch(FetchDescriptor<ReminderList>())) ?? []
        #expect(remaining.contains { $0.persistentModelID == bucketID })
        #expect(work.inboxBucket?.persistentModelID == bucketID)
    }

    @Test func bucketCannotBeReordered() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let bucket = makeBucket(for: work, in: context)
        let alpha = ReminderList(name: "Alpha", sortOrder: "a", group: work)
        let beta = ReminderList(name: "Beta", sortOrder: "m", group: work)
        context.insert(alpha)
        context.insert(beta)
        try? context.save()
        let bucketOrder = bucket.sortOrder

        let vm = createViewModel(
            lists: [bucket, alpha, beta], groups: [work], allTasks: [], context: context
        )
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 2, in: [bucket, alpha, beta])

        #expect(bucket.sortOrder == bucketOrder)
    }

    /// Bucket identity is derived, not stored: a list is the area's bucket because it is
    /// that area's list named "Inbox", and it stops being the bucket the moment it is
    /// renamed or moved out of an area.
    @Test func bucketIdentityIsDerivedFromAreaAndName() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let work = area("Work", order: "a", context: context)
        let list = ReminderList(name: "Inbox", sortOrder: "m", group: work)
        context.insert(list)
        try? context.save()

        let vm = createViewModel(lists: [list], groups: [work], allTasks: [], context: context)
        #expect(vm.isBucket(list))
        #expect(work.inboxBucket?.persistentModelID == list.persistentModelID)

        list.name = "Claimant"
        try? context.save()
        #expect(vm.isBucket(list) == false)
        #expect(work.inboxBucket == nil)
    }

    /// A list named "Inbox" that belongs to no area is the legacy global Inbox, not a
    /// bucket — the guard must not protect it.
    @Test func ungroupedInboxIsNotTreatedAsBucket() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let floating = ReminderList(name: "Inbox")
        context.insert(floating)
        try? context.save()

        let vm = createViewModel(lists: [floating], groups: [], allTasks: [], context: context)
        #expect(vm.isBucket(floating) == false)
        #expect(vm.ungroupedLists.contains { $0.persistentModelID == floating.persistentModelID })
    }
}
