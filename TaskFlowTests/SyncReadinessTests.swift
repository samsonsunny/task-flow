import Testing
import Foundation
import SwiftData
@testable import TaskFlow

private struct TaskSnapshot: Equatable {
    let id: PersistentIdentifier
    let listID: PersistentIdentifier?
    let title: String?
    let dueDate: Date?
    let createdAt: Date?
    let isCompleted: Bool?
    let isFlagged: Bool?
    let sortOrder: Int?
}

@MainActor
struct SyncReadinessTests {
    let container: ModelContainer
    let context: ModelContext

    init() {
        container = TaskPreviewData.container()
        context = container.mainContext
    }

    private func makeMigrationDefaults() -> (UserDefaults, String) {
        let suiteName = "TaskFlowMigrationTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }

    private func taskSnapshots(_ tasks: [TaskItem]) -> [TaskSnapshot] {
        tasks.map {
            TaskSnapshot(
                id: $0.persistentModelID,
                listID: $0.reminderList?.persistentModelID,
                title: $0.taskTitle,
                dueDate: $0.dueDate,
                createdAt: $0.createdAt,
                isCompleted: $0.isCompleted,
                isFlagged: $0.isFlagged,
                sortOrder: $0.sortOrder
            )
        }
    }

    // MARK: - V10 CloudKit-compatible model defaults

    @Test func optionalToManyRelationshipsReadAsEmptyByDefault() {
        let task = TaskItem(taskTitle: "Root")
        let list = ReminderList(name: "Test")
        let group = ReminderListGroup(name: "Group")
        context.insert(task)
        context.insert(list)
        context.insert(group)

        #expect(task.tagsArray.isEmpty)
        #expect(task.subtasksArray.isEmpty)
        #expect(list.remindersArray.isEmpty)
        #expect(group.listsArray.isEmpty)
    }

    @Test func attributeDefaultsSatisfyCloudKitRequirement() {
        #expect(ReminderList().name == "")
        #expect(ReminderTag(label: "Work").normalizedLabel == "work")
        #expect(ReminderListGroup().name == "")
    }

    @Test func toManyRelationshipsInferInverseAndBackfill() {
        let list = ReminderList(name: "Test")
        context.insert(list)
        let task = TaskItem(taskTitle: "Task")
        task.reminderList = list
        context.insert(task)

        #expect(task.reminderList?.persistentModelID == list.persistentModelID)
        #expect(list.remindersArray.map(\.persistentModelID).contains(task.persistentModelID))
    }

    // MARK: - Area reconciler

    @Test func areaReconcilerReparentsFloatingInboxToFirstGroup() {
        let work = ReminderListGroup(name: "Work")
        let personal = ReminderListGroup(name: "Personal")
        context.insert(work)
        context.insert(personal)
        let bucket = ReminderList(name: "Inbox")
        bucket.group = work
        context.insert(bucket)

        let floatingInbox = ReminderList(name: "Inbox")
        context.insert(floatingInbox)
        let task = TaskItem(taskTitle: "From floating")
        task.reminderList = floatingInbox
        context.insert(task)
        try? context.save()
        let floatingID = floatingInbox.persistentModelID
        let bucketID = bucket.persistentModelID

        reconcileLockedAreas(in: context)

        let groups = (try? context.fetch(FetchDescriptor<ReminderListGroup>())) ?? []
        let workGroup = groups.first { $0.name == "Work" }!
        let personalGroup = groups.first { $0.name == "Personal" }!
        #expect(workGroup.inboxBucket?.persistentModelID == bucketID)
        #expect(personalGroup.inboxBucket != nil)
        #expect(personalGroup.inboxBucket?.persistentModelID != bucketID)

        let allLists = (try? context.fetch(FetchDescriptor<ReminderList>())) ?? []
        #expect(allLists.contains { $0.persistentModelID == floatingID } == false)
        #expect(allLists.filter { $0.name == "Inbox" }.count == 2)
        #expect(task.reminderList?.persistentModelID == bucketID)
    }

    @Test func areaReconcilerCreatesMissingBucketForGroup() {
        let work = ReminderListGroup(name: "Work")
        context.insert(work)
        let normalList = ReminderList(name: "Calls")
        normalList.group = work
        context.insert(normalList)
        try? context.save()

        reconcileLockedAreas(in: context)

        #expect(work.inboxBucket != nil)
        #expect(work.inboxBucket?.group == work)
        #expect(work.listsArray.map(\.name).contains("Inbox"))
    }

    @Test func areaReconcilerSweepsNilListTasksToFirstGroupBucket() {
        let work = ReminderListGroup(name: "Work")
        context.insert(work)
        let bucket = ReminderList(name: "Inbox")
        bucket.group = work
        context.insert(bucket)

        let orphan = TaskItem(taskTitle: "Orphan")
        context.insert(orphan)
        try? context.save()

        reconcileLockedAreas(in: context)

        #expect(orphan.reminderList?.persistentModelID == bucket.persistentModelID)
    }

    @Test func areaReconcilerLeavesTwoAreaBucketsUntouched() {
        let work = ReminderListGroup(name: "Work")
        let personal = ReminderListGroup(name: "Personal")
        context.insert(work)
        context.insert(personal)

        let workBucket = ReminderList(name: "Inbox")
        workBucket.group = work
        context.insert(workBucket)

        let personalBucket = ReminderList(name: "Inbox")
        personalBucket.group = personal
        context.insert(personalBucket)
        try? context.save()

        reconcileLockedAreas(in: context)

        let inboxes = ((try? context.fetch(FetchDescriptor<ReminderList>())) ?? [])
            .filter { $0.name == "Inbox" }
        #expect(inboxes.count == 2)
    }

    @Test func migrationReparentsGlobalInboxAndPreservesTaskData() {
        let (defaults, suiteName) = makeMigrationDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let work = ReminderListGroup(name: "Work", sortOrder: "a", createdAt: Date(timeIntervalSince1970: 100))
        let personal = ReminderListGroup(name: "Personal", sortOrder: "b", createdAt: Date(timeIntervalSince1970: 200))
        let globalInbox = ReminderList(name: "Inbox", createdAt: Date(timeIntervalSince1970: 50))
        let task = TaskItem(
            taskTitle: "Preserve me",
            dueDate: Date(timeIntervalSince1970: 300),
            createdAt: Date(timeIntervalSince1970: 400),
            reminderList: globalInbox,
            sortOrder: 7
        )
        task.isCompleted = true
        task.completionDate = Date(timeIntervalSince1970: 500)
        task.isFlagged = true
        context.insert(work)
        context.insert(personal)
        context.insert(globalInbox)
        context.insert(task)
        try? context.save()
        let before = taskSnapshots([task])

        migrateGlobalInboxToFirstGroup(in: context, defaults: defaults)

        let groups = (try? context.fetch(FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        #expect(groups.first?.persistentModelID == work.persistentModelID)
        #expect(work.inboxBucket?.persistentModelID == globalInbox.persistentModelID)
        #expect(globalInbox.group?.persistentModelID == work.persistentModelID)
        #expect(taskSnapshots([task]) == before)
        #expect(task.reminderList?.persistentModelID == globalInbox.persistentModelID)
    }

    @Test func migrationAdoptsGlobalInboxWhenStoreHasNoGroups() {
        let (defaults, suiteName) = makeMigrationDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let globalInbox = ReminderList(name: "Inbox")
        let task = TaskItem(taskTitle: "Legacy task", reminderList: globalInbox)
        context.insert(globalInbox)
        context.insert(task)
        try? context.save()
        let globalInboxID = globalInbox.persistentModelID
        let taskID = task.persistentModelID

        migrateGlobalInboxToFirstGroup(in: context, defaults: defaults)

        let groups = (try? context.fetch(FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        #expect(groups.map(\.name) == ["Work", "Personal"])
        let work = groups.first { $0.name == "Work" }!
        let personal = groups.first { $0.name == "Personal" }!
        #expect(work.inboxBucket?.persistentModelID == globalInboxID)
        #expect(globalInbox.group?.persistentModelID == work.persistentModelID)
        #expect(personal.inboxBucket?.persistentModelID != globalInboxID)
        #expect(personal.inboxBucket?.group?.persistentModelID == personal.persistentModelID)
        #expect(task.reminderList?.persistentModelID == globalInboxID)
        #expect((try? context.fetch(FetchDescriptor<TaskItem>()))?.contains { $0.persistentModelID == taskID } == true)
    }

    @Test func migrationIsIdempotent() {
        let (defaults, suiteName) = makeMigrationDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let work = ReminderListGroup(name: "Work", sortOrder: "a")
        let globalInbox = ReminderList(name: "Inbox")
        let task = TaskItem(taskTitle: "Task", reminderList: globalInbox, sortOrder: 3)
        context.insert(work)
        context.insert(globalInbox)
        context.insert(task)
        try? context.save()

        migrateGlobalInboxToFirstGroup(in: context, defaults: defaults)
        let groupsAfterFirstRun = (try? context.fetch(FetchDescriptor<ReminderListGroup>())) ?? []
        let listsAfterFirstRun = (try? context.fetch(FetchDescriptor<ReminderList>())) ?? []
        let tasksAfterFirstRun = taskSnapshots([task])
        let listIDsAfterFirstRun = listsAfterFirstRun.map(\.persistentModelID)
        let groupIDsAfterFirstRun = groupsAfterFirstRun.map(\.persistentModelID)

        migrateGlobalInboxToFirstGroup(in: context, defaults: defaults)

        let listsAfterSecondRun = (try? context.fetch(FetchDescriptor<ReminderList>())) ?? []
        #expect(listsAfterSecondRun.map(\.persistentModelID) == listIDsAfterFirstRun)
        #expect((try? context.fetch(FetchDescriptor<ReminderListGroup>()))?.map(\.persistentModelID) == groupIDsAfterFirstRun)
        #expect(taskSnapshots([task]) == tasksAfterFirstRun)
        #expect(defaults.bool(forKey: "did_migrate_global_inbox_to_first_group_v2"))
    }

    @Test func migrationDoesNotDeleteTasksInPlainReparentPath() {
        let (defaults, suiteName) = makeMigrationDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let work = ReminderListGroup(name: "Work", sortOrder: "a")
        let globalInbox = ReminderList(name: "Inbox")
        let task = TaskItem(taskTitle: "Only task", reminderList: globalInbox, sortOrder: 11)
        context.insert(work)
        context.insert(globalInbox)
        context.insert(task)
        try? context.save()
        let before = taskSnapshots([task])
        let taskID = task.persistentModelID

        migrateGlobalInboxToFirstGroup(in: context, defaults: defaults)

        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        #expect(tasks.count == 1)
        #expect(tasks.first?.persistentModelID == taskID)
        #expect(taskSnapshots(tasks) == before)
    }


    @Test func backfillPreservesExistingSortOrdersAndFillsOnlyMissing() {
        let list = ReminderList(name: "List")
        context.insert(list)

        let a = TaskItem(taskTitle: "A", createdAt: Date(timeIntervalSince1970: 100))
        a.reminderList = list
        a.sortOrder = 0
        context.insert(a)

        let b = TaskItem(taskTitle: "B", createdAt: Date(timeIntervalSince1970: 200))
        b.reminderList = list
        b.sortOrder = 5
        context.insert(b)

        let c = TaskItem(taskTitle: "C", createdAt: Date(timeIntervalSince1970: 150))
        c.reminderList = list
        context.insert(c)

        let d = TaskItem(taskTitle: "D", createdAt: Date(timeIntervalSince1970: 250))
        d.reminderList = list
        context.insert(d)
        try? context.save()

        backfillSortOrdersIfNeeded(in: context)

        #expect(a.sortOrder == 0)
        #expect(b.sortOrder == 5)
        #expect(c.sortOrder == 6)
        #expect(d.sortOrder == 7)
    }

    @Test func listBackfillOrdersBucketsFirstWithinGroupAndGroupByGroupOrder() {
        let work = ReminderListGroup(name: "Work", sortOrder: "a")
        let personal = ReminderListGroup(name: "Personal", sortOrder: "b")
        context.insert(work)
        context.insert(personal)

        let workBucket = makeBucket(for: work, in: context)
        let workZebra = ReminderList(name: "Zebra", createdAt: Date(timeIntervalSince1970: 10), group: work)
        let workAlpha = ReminderList(name: "Alpha", createdAt: Date(timeIntervalSince1970: 20), group: work)
        let personalBucket = makeBucket(for: personal, in: context)
        let personalList = ReminderList(name: "Errands", createdAt: Date(timeIntervalSince1970: 30), group: personal)
        [workZebra, workAlpha, personalList].forEach {
            $0.sortOrder = nil
            context.insert($0)
        }
        [workBucket, personalBucket].forEach { $0.sortOrder = nil }
        try? context.save()

        backfillListSortOrdersIfNeeded(in: context)

        #expect(workBucket.sortOrder != nil)
        #expect(workAlpha.sortOrder != nil)
        #expect(workZebra.sortOrder != nil)
        #expect(personalBucket.sortOrder != nil)
        #expect(personalList.sortOrder != nil)

        let workOrder = [workBucket, workAlpha, workZebra]
        for (lhs, rhs) in zip(workOrder, workOrder.dropFirst()) {
            #expect(lhs.sortOrder! < rhs.sortOrder!)
        }
        for workList in workOrder {
            for personalListItem in [personalBucket, personalList] {
                #expect(workList.sortOrder! < personalListItem.sortOrder!)
            }
        }
        #expect(personalBucket.sortOrder! < personalList.sortOrder!)
    }

    @Test func listBackfillIsIdempotentAndPreservesExistingOrders() {
        let work = ReminderListGroup(name: "Work", sortOrder: "a")
        context.insert(work)
        let bucket = makeBucket(for: work, in: context)
        let existing = ReminderList(name: "Alpha", sortOrder: "m", group: work)
        let missing = ReminderList(name: "Beta", group: work)
        context.insert(existing)
        context.insert(missing)
        try? context.save()

        backfillListSortOrdersIfNeeded(in: context)
        let firstPass = (try? context.fetch(FetchDescriptor<ReminderList>()))?
            .compactMap { $0.sortOrder } ?? []
        #expect(missing.sortOrder != nil)
        #expect(bucket.sortOrder != nil)

        backfillListSortOrdersIfNeeded(in: context)
        let secondPass = (try? context.fetch(FetchDescriptor<ReminderList>()))?
            .compactMap { $0.sortOrder } ?? []
        #expect(firstPass.sorted() == secondPass.sorted())
    }

    @Test func backfillDoesNothingWhenAllTasksHaveSortOrders() {
        let list = ReminderList(name: "List")
        context.insert(list)
        let task = TaskItem(taskTitle: "Task")
        task.reminderList = list
        task.sortOrder = 3
        context.insert(task)
        try? context.save()

        backfillSortOrdersIfNeeded(in: context)

        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.sortOrder == nil })
        let missing = (try? context.fetch(descriptor)) ?? []
        #expect(missing.isEmpty)
        #expect(task.sortOrder == 3)
    }
}