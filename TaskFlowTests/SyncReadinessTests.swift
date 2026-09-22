import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct SyncReadinessTests {
    let container: ModelContainer
    let context: ModelContext

    init() {
        container = TaskPreviewData.container()
        context = container.mainContext
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

    // MARK: - Inbox reconciler

    @Test func inboxReconcilerMergesDuplicateListsWithoutLosingTasks() {
        let inboxA = ReminderList(name: ReminderDefaults.defaultListName)
        let inboxB = ReminderList(name: ReminderDefaults.defaultListName)
        context.insert(inboxA)
        context.insert(inboxB)

        let taskA = TaskItem(taskTitle: "From A")
        taskA.reminderList = inboxA
        context.insert(taskA)
        let taskB = TaskItem(taskTitle: "From B")
        taskB.reminderList = inboxB
        context.insert(taskB)
        try? context.save()

        reconcileInboxLists(in: context)

        let descriptor = FetchDescriptor<ReminderList>()
        let remaining = (try? context.fetch(descriptor)) ?? []
        let inboxes = remaining.filter { $0.name == ReminderDefaults.defaultListName }
        #expect(inboxes.count == 1)

        let merged = inboxes[0].remindersArray
        #expect(merged.count == 2)
        #expect(Set(merged.map(\.safeTitle)) == ["From A", "From B"])
    }

    @Test func inboxReconcilerLeavesSingleInboxUntouched() {
        let inbox = ReminderList(name: ReminderDefaults.defaultListName)
        context.insert(inbox)
        let task = TaskItem(taskTitle: "Task")
        task.reminderList = inbox
        context.insert(task)
        try? context.save()

        reconcileInboxLists(in: context)

        let descriptor = FetchDescriptor<ReminderList>()
        let inboxes = ((try? context.fetch(descriptor)) ?? []).filter { $0.name == ReminderDefaults.defaultListName }
        #expect(inboxes.count == 1)
        #expect(inboxes[0].remindersArray.count == 1)
    }

    // MARK: - Data-gated sort-order backfill

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