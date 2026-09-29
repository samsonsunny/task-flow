import Testing
import Foundation
import SwiftData
@testable import TaskFlow

/// Covers the locked-area invariant: exactly two locked areas, and the extra-area merge
/// never loses, duplicates, or creates a task.
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
        #expect(result.allSatisfy { $0.isLocked })
        #expect(result.map(\.name) == ["Work", "Personal"])
        #expect(result.allSatisfy { $0.inboxBucket != nil })
    }

    /// Areas are adopted by name, not created alongside existing ones — otherwise a user
    /// upgrading would silently gain a second Personal.
    @Test func existingAreasAreAdoptedAndLocked() {
        _ = seeded(["Personal", "Work"])
        _ = reconcileLockedAreas(in: context)

        let result = groups()
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.isLocked })
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

    // MARK: - Extra-area merge

    @Test func extraAreaIsFoldedIntoWork() {
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

        let taskID = task.persistentModelID

        let state = reconcileLockedAreas(in: context)

        #expect(state?.didMerge == true)
        #expect(state?.mergedAreaCount == 2)
        #expect(groups().map(\.name) == ["Work", "Personal"])

        // The foreign bucket's task moves to Work's bucket by pointer; it is not recreated.
        #expect(task.persistentModelID == taskID)
        #expect(task.reminderList?.persistentModelID == workBucket.persistentModelID)

        // The emptied foreign bucket is gone, so there are exactly two Inboxes left.
        #expect(lists().filter { $0.name == "Inbox" }.count == 2)
        #expect(lists().contains { $0.persistentModelID == sideBucket.persistentModelID } == false)

        // Surviving lists are reparented into Work and are normal lists, not buckets.
        // Work keeps exactly one bucket, so the reparented list cannot have become one.
        #expect(sideList.group?.persistentModelID == work.persistentModelID)
        #expect(sideList.isBucket == false)
        #expect(sideList.sortOrder != nil)
    }

    /// The merge is only safe if it preserves every task field. `reminderList` is the only
    /// property that may change.
    @Test func mergePreservesEveryTaskButItsList() {
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

    @Test func mergeIsIdempotent() {
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

        let second = reconcileLockedAreas(in: context)

        #expect(second?.didMerge == false)
        #expect(groups().count == firstGroupCount)
        #expect(tasks().count == firstTaskCount)
        #expect(task.reminderList?.persistentModelID == firstList)
    }

    @Test func mergeClearsStrayBucketPointers() {
        let all = seeded(["Work", "Personal", "Side Hustle"])
        let sideHustle = all[2]
        let sideBucket = makeBucket(for: sideHustle, in: context)
        try? context.save()
        let strayID = sideBucket.persistentModelID

        _ = reconcileLockedAreas(in: context)

        // The foreign bucket is deleted rather than reparented, so no area is left owning
        // two Inboxes and the merged-away area's bucket pointer cannot survive.
        #expect(lists().contains { $0.persistentModelID == strayID } == false)
        #expect(lists().filter { $0.isBucket }.count == groups().count)
        #expect(groups().allSatisfy { $0.inboxBucket != nil })
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
}
