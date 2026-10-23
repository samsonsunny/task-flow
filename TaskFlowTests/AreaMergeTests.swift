import Testing
import Foundation
import SwiftData
@testable import TaskFlow

/// Covers the domain invariant: Work and Personal exist and stay locked, every domain owns
/// an Inbox bucket, and any extra group is folded into Work without losing lists or tasks.
@MainActor
struct AreaMergeTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() {
        container = TaskPreviewData.container()
        context = container.mainContext
    }

    private func groups() -> [ReminderListGroup] {
        (try? context.fetch(
            FetchDescriptor<ReminderListGroup>(sortBy: [SortDescriptor(\.sortOrder)])
        )) ?? []
    }

    private func lists() -> [ReminderList] {
        (try? context.fetch(FetchDescriptor<ReminderList>())) ?? []
    }

    private func tasks() -> [TaskItem] {
        (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
    }

    private func seeded(_ names: [String]) -> [ReminderListGroup] {
        names.enumerated().map { index, name in
            let group = ReminderListGroup(
                name: name,
                sortOrder: String(UnicodeScalar(97 + index) ?? "a")
            )
            context.insert(group)
            return group
        }
    }

    // MARK: - Invariant

    @Test func emptyStoreGetsExactlyTwoLockedAreas() {
        _ = reconcileLockedAreas(in: context)

        let result = groups()
        #expect(result.count == 2)
        for group in result {
            #expect(group.isLocked)
        }
        #expect(result.map(\.name) == ["Work", "Personal"])
        for group in result {
            #expect(group.inboxBucket != nil)
        }
    }

    /// Areas are adopted by name, not created alongside existing ones — otherwise a user
    /// upgrading would silently gain a second Personal.
    @Test func existingAreasAreAdoptedAndLocked() {
        _ = seeded(["Personal", "Work"])
        _ = reconcileLockedAreas(in: context)

        let result = groups()
        #expect(result.count == 2)
        #expect(result.map(\.name) == ["Work", "Personal"])
    }

    @Test func personalIsSeededWhenMissing() {
        _ = seeded(["Work"])
        _ = reconcileLockedAreas(in: context)

        let result = groups()
        #expect(result.count == 2)
        #expect(result.map(\.name) == ["Work", "Personal"])
        #expect(result.last?.inboxBucket != nil)
    }

    @Test func eachAreaOwnsItsOwnBucket() {
        _ = reconcileLockedAreas(in: context)
        let result = groups()
        let workBucket = result[0].inboxBucket?.persistentModelID
        let personalBucket = result[1].inboxBucket?.persistentModelID

        #expect(workBucket != nil)
        #expect(personalBucket != nil)
        #expect(workBucket != personalBucket)
        #expect(result[0].inboxBucket?.group?.persistentModelID == result[0].persistentModelID)
        #expect(result[1].inboxBucket?.group?.persistentModelID == result[1].persistentModelID)
    }

    // MARK: - Extra groups

    @Test func extraGroupsFoldIntoWorkPreservingListsAndTasks() {
        let all = seeded(["Work", "Personal", "Side Hustle", "Volunteering"])
        let work = all[0]
        let workBucket = makeBucket(for: work, in: context)

        let sideHustle = all[2]
        let sideBucket = makeBucket(for: sideHustle, in: context)
        let task = TaskItem(taskTitle: "Client invoice")
        task.reminderList = sideBucket
        context.insert(task)

        let sideList = ReminderList(name: "Clients", group: sideHustle)
        context.insert(sideList)
        try? context.save()

        _ = reconcileLockedAreas(in: context)

        let result = groups()
        #expect(result.map(\.name) == ["Work", "Personal"])
        #expect(result.allSatisfy { $0.isLocked })

        // The bucket task moves to Work's Inbox; ordinary lists become Work lists.
        #expect(task.reminderList?.persistentModelID == workBucket.persistentModelID)
        #expect(sideList.group?.persistentModelID == work.persistentModelID)
        #expect(lists().filter { $0.isBucket }.count == 2)
        #expect(listContainsTask(workBucket, task: task))
    }

    @Test func foldingPreservesEveryTaskProperty() {
        let all = seeded(["Work", "Personal", "Side Hustle"])
        let sideHustle = all[2]
        let sideBucket = makeBucket(for: sideHustle, in: context)

        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let task = TaskItem(taskTitle: "Invoice", dueDate: due)
        task.reminderList = sideBucket
        task.notes = "keep me"
        task.isCompleted = true
        task.sortOrder = 7
        context.insert(task)
        try? context.save()

        let id = task.persistentModelID
        _ = reconcileLockedAreas(in: context)

        let after = tasks().first { $0.persistentModelID == id }
        #expect(tasks().count == 1)
        #expect(after?.taskTitle == "Invoice")
        #expect(after?.notes == "keep me")
        #expect(after?.dueDate == due)
        #expect(after?.isCompleted == true)
        #expect(after?.sortOrder == 7)
        #expect(after?.reminderList?.group?.name == "Work")
    }

    @Test func foldingIsIdempotent() {
        let all = seeded(["Work", "Personal", "Side Hustle"])
        let sideBucket = makeBucket(for: all[2], in: context)
        let task = TaskItem(taskTitle: "Task")
        task.reminderList = sideBucket
        context.insert(task)
        try? context.save()

        _ = reconcileLockedAreas(in: context)
        let firstGroupCount = groups().count
        let firstTaskCount = tasks().count
        let firstList = task.reminderList?.persistentModelID

        _ = reconcileLockedAreas(in: context)

        #expect(groups().count == firstGroupCount)
        #expect(tasks().count == firstTaskCount)
        #expect(task.reminderList?.persistentModelID == firstList)
    }

    @Test func extraGroupWithoutBucketStillFoldsItsLists() {
        let all = seeded(["Work", "Personal", "Side Hustle"])
        let sideHustle = all[2]
        let custom = ReminderList(name: "Clients", group: sideHustle)
        context.insert(custom)
        try? context.save()

        _ = reconcileLockedAreas(in: context)

        #expect(groups().map(\.name) == ["Work", "Personal"])
        #expect(custom.group?.name == "Work")
        #expect(custom.group?.inboxBucket != nil)
    }

    // MARK: - Strays

    @Test func orphanTasksLandInWorkBucket() {
        _ = reconcileLockedAreas(in: context)
        let orphan = TaskItem(taskTitle: "Orphan")
        context.insert(orphan)
        try? context.save()

        _ = reconcileLockedAreas(in: context)

        #expect(orphan.reminderList?.group?.name == "Work")
        #expect(orphan.reminderList?.persistentModelID == groups()[0].inboxBucket?.persistentModelID)
    }

    @Test func strayListIsAdoptedIntoWork() {
        _ = reconcileLockedAreas(in: context)
        let stray = ReminderList(name: "Stray")
        context.insert(stray)
        try? context.save()

        _ = reconcileLockedAreas(in: context)

        #expect(stray.group?.name == "Work")
    }

    @Test func legacyFloatingInboxIsFoldedNotDuplicated() {
        let all = seeded(["Work", "Personal"])
        let workBucket = makeBucket(for: all[0], in: context)
        let floating = ReminderList(name: "Inbox")
        context.insert(floating)
        let task = TaskItem(taskTitle: "Legacy")
        task.reminderList = floating
        context.insert(task)
        try? context.save()

        _ = reconcileLockedAreas(in: context)

        #expect(lists().filter { $0.name == "Inbox" }.count == 2)
        #expect(lists().contains { $0.persistentModelID == floating.persistentModelID } == false)
        #expect(task.reminderList?.persistentModelID == workBucket.persistentModelID)
        #expect(tasks().count == 1)
    }

    // MARK: - Capture resolution

    @Test func captureResolvesRequestedAreaBucket() {
        _ = reconcileLockedAreas(in: context)
        let personal = groups().first { $0.name == "Personal" }!

        let bucket = resolveAreaBucket(for: personal.persistentModelID, in: context)

        #expect(bucket.persistentModelID == personal.inboxBucket?.persistentModelID)
        #expect(bucket.group?.name == "Personal")
    }

    /// No positional fallback: an unknown id must still land in a real bucket rather than
    /// crash or return something unfiled.
    @Test func captureWithUnknownAreaFallsBackToWork() {
        _ = reconcileLockedAreas(in: context)
        let bucket = resolveAreaBucket(for: nil, in: context)
        #expect(bucket.group?.name == "Work")
    }

    private func listContainsTask(_ list: ReminderList, task: TaskItem) -> Bool {
        list.remindersArray.contains { $0.persistentModelID == task.persistentModelID }
    }
}
