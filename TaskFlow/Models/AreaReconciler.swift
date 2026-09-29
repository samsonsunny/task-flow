import Foundation
import SwiftData

/// Canonical names that the whole app keys off.
///
/// The locked-area flags and the bucket link are derived from these strings rather than
/// persisted, because the CloudKit production schema for `ReminderListGroup` and
/// `ReminderList` is sealed: a new column on either record makes every mirroring export
/// abort. `reconcileLockedAreas(in:)` runs on every launch and normalizes the store to
/// exactly two areas named `work`/`personal`, each owning one list named `inbox`, which
/// makes the names a sound key.
enum AreaNames {
    static let work = "Work"
    static let personal = "Personal"
    static let inbox = "Inbox"
}

// MARK: - One-time migration: global Inbox → first group's bucket

@MainActor
func migrateGlobalInboxToFirstGroup(
    in modelContext: ModelContext,
    defaults: UserDefaults = .standard
) {
    let key = "did_migrate_global_inbox_to_first_group_v2"
    guard !defaults.bool(forKey: key) else { return }

    let allLists = (try? modelContext.fetch(FetchDescriptor<ReminderList>())) ?? []
    let globalInbox = allLists.first { $0.group == nil && $0.name == AreaNames.inbox }
    var groups = orderedGroups(in: modelContext)
    var firstGroup: ReminderListGroup

    if let existing = groups.first {
        firstGroup = existing
    } else if let globalInbox {
        let work = ReminderListGroup(name: AreaNames.work)
        modelContext.insert(work)
        work.assignInitialSortOrder(in: modelContext)
        globalInbox.group = work

        let personal = ReminderListGroup(name: AreaNames.personal)
        modelContext.insert(personal)
        personal.assignInitialSortOrder(in: modelContext)
        let personalBucket = ReminderList(name: AreaNames.inbox)
        personalBucket.group = personal
        personalBucket.assignInitialSortOrder(in: modelContext)
        modelContext.insert(personalBucket)
        firstGroup = work
    } else {
        firstGroup = seedDefaultAreas(in: modelContext)[0]
    }

    if let globalInbox, globalInbox.persistentModelID != firstGroup.inboxBucket?.persistentModelID {
        if let existingBucket = firstGroup.inboxBucket {
            for task in globalInbox.remindersArray {
                task.reminderList = existingBucket
            }
            modelContext.delete(globalInbox)
        } else {
            globalInbox.group = firstGroup
        }
    }

    for list in allLists where list.group == nil && list.persistentModelID != globalInbox?.persistentModelID {
        list.group = firstGroup
    }

    do {
        try modelContext.save()
        defaults.set(true, forKey: key)
    } catch {
        modelContext.rollback()
    }
}

@MainActor
func orderedGroups(in modelContext: ModelContext) -> [ReminderListGroup] {
    let descriptor = FetchDescriptor<ReminderListGroup>(sortBy: [
        SortDescriptor(\.sortOrder),
        SortDescriptor(\.createdAt)
    ])
    return (try? modelContext.fetch(descriptor)) ?? []
}

@MainActor
@discardableResult
func makeBucket(for group: ReminderListGroup, in modelContext: ModelContext) -> ReminderList {
    let bucket = ReminderList(name: AreaNames.inbox)
    bucket.group = group
    bucket.assignInitialSortOrder(in: modelContext)
    modelContext.insert(bucket)
    return bucket
}

// MARK: - Canonical area seeding (Work, Personal, each with an Inbox bucket)

@MainActor
@discardableResult
func seedDefaultAreas(in context: ModelContext) -> [ReminderListGroup] {
    let groupDescriptor = FetchDescriptor<ReminderListGroup>()
    let existing = (try? context.fetch(groupDescriptor)) ?? []
    if !existing.isEmpty {
        for group in existing where group.inboxBucket == nil {
            makeBucket(for: group, in: context)
        }
        try? context.save()
        return orderedGroups(in: context)
    }

    let work = ReminderListGroup(name: AreaNames.work)
    context.insert(work)
    work.assignInitialSortOrder(in: context)
    let workBucket = ReminderList(name: AreaNames.inbox)
    workBucket.group = work
    workBucket.assignInitialSortOrder(in: context)
    context.insert(workBucket)

    let personal = ReminderListGroup(name: AreaNames.personal)
    context.insert(personal)
    personal.assignInitialSortOrder(in: context)
    let personalBucket = ReminderList(name: AreaNames.inbox)
    personalBucket.group = personal
    personalBucket.assignInitialSortOrder(in: context)
    context.insert(personalBucket)

    try? context.save()
    return [work, personal]
}

// MARK: - Locked-area state

/// The outcome of one `reconcileLockedAreas(in:)` pass. Returned so tests can assert on
/// what the merge actually did rather than only on the resulting shape.
struct LockedAreaState {
    var work: ReminderListGroup
    var personal: ReminderListGroup
    var mergedAreaCount: Int = 0
    var mergedListCount: Int = 0
    var movedTaskCount: Int = 0

    var didMerge: Bool { mergedAreaCount > 0 }
}

// MARK: - Recurring locked-area reconciler

/// Enforces the store invariant: exactly two locked areas, Work and Personal, each owning
/// an Inbox bucket, with every list and task living inside one of them.
///
/// Runs on every launch and is gated by no persisted flag, so an extra area synced down
/// from a device still running an older build is merged on the next launch. The pass is
/// idempotent — a second run against a conforming store changes nothing.
///
/// The merge never creates, deletes, or modifies a `TaskItem`; it only reassigns the
/// `reminderList` pointer of tasks living in a foreign area's bucket.
@MainActor
@discardableResult
func reconcileLockedAreas(in modelContext: ModelContext) -> LockedAreaState? {
    var state = resolveLockedAreas(in: modelContext)
    guard let work = state?.work, let personal = state?.personal else { return nil }

    // Steps 3a–3c: merge every area that is neither Work nor Personal into Work.
    let workID = work.persistentModelID
    let personalID = personal.persistentModelID
    let extras = orderedGroups(in: modelContext).filter {
        $0.persistentModelID != workID && $0.persistentModelID != personalID
    }

    for extra in extras {
        let outcome = mergeExtraArea(extra, into: work, in: modelContext)
        state?.mergedAreaCount += 1
        state?.mergedListCount += outcome.listCount
        state?.movedTaskCount += outcome.taskCount
    }

    // Each locked area must own its own bucket. `inboxBucket` only returns a list that is
    // already inside the area, so a missing or stolen bucket is the same condition.
    if work.inboxBucket == nil {
        makeBucket(for: work, in: modelContext)
    }
    if personal.inboxBucket == nil {
        makeBucket(for: personal, in: modelContext)
    }

    // No list may be stranded without an area, and no task without a list. The one-time
    // migration handles the legacy global Inbox, but it is UserDefaults-gated, so the
    // recurring pass has to be able to adopt strays that appear later (e.g. from a device
    // still running an older build).
    if let workBucket = work.inboxBucket {
        let orphanListDescriptor = FetchDescriptor<ReminderList>(predicate: #Predicate { $0.group == nil })
        let orphanLists = (try? modelContext.fetch(orphanListDescriptor)) ?? []
        for list in orphanLists {
            // A stray named Inbox is the legacy global Inbox: fold its tasks into Work's
            // bucket and drop the duplicate rather than creating a third bucket. Without
            // the name check, reparenting it would make it a *second* bucket in Work.
            if list.name == AreaNames.inbox, list.persistentModelID != workBucket.persistentModelID {
                for task in list.remindersArray {
                    task.reminderList = workBucket
                }
                modelContext.delete(list)
            } else {
                list.group = work
            }
        }

        let orphanDescriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.reminderList == nil })
        let orphans = (try? modelContext.fetch(orphanDescriptor)) ?? []
        for task in orphans {
            task.reminderList = workBucket
        }
    }

    // Rank the lists the merge reparented, then sweep any other unranked list. The
    // non-saving variant matters: this pass must commit as one save, not a backfill save
    // followed by a merge save.
    backfillListSortOrders(in: modelContext)

    // Step 5: one save for the whole pass; a failure leaves the store untouched.
    do {
        try modelContext.save()
    } catch {
        modelContext.rollback()
    }
    return state
}

/// Steps 1 and 2: adopt or seed Work and Personal, and lock both.
@MainActor
private func resolveLockedAreas(in modelContext: ModelContext) -> LockedAreaState? {
    let groups = orderedGroups(in: modelContext)

    // Step 1 — Work by name, else by position (sortOrder, then createdAt), else seeded.
    let work: ReminderListGroup
    if let named = groups.first(where: { $0.name == AreaNames.work }) {
        work = named
    } else if let first = groups.first {
        work = first
    } else {
        work = ReminderListGroup(name: AreaNames.work)
        modelContext.insert(work)
        work.assignInitialSortOrder(in: modelContext)
    }
    // Renaming to the canonical name is what marks the area locked: `isLocked` is derived
    // from the name because the CloudKit production schema has no column for it.
    work.name = AreaNames.work

    // Step 2 — Personal by name, excluding Work, else seeded.
    let personal: ReminderListGroup
    if let named = groups.first(where: {
        $0.name == AreaNames.personal && $0.persistentModelID != work.persistentModelID
    }) {
        personal = named
    } else {
        personal = ReminderListGroup(name: AreaNames.personal)
        modelContext.insert(personal)
        personal.assignInitialSortOrder(in: modelContext)
    }
    personal.name = AreaNames.personal

    return LockedAreaState(work: work, personal: personal)
}

/// Steps 3a–3c: fold one non-locked area into Work.
///
/// The foreign bucket is *not* reparented — its tasks are repointed at Work's own bucket
/// and the emptied bucket is deleted, so Work keeps exactly one bucket.
@MainActor
private func mergeExtraArea(
    _ extra: ReminderListGroup,
    into work: ReminderListGroup,
    in modelContext: ModelContext
) -> (listCount: Int, taskCount: Int) {
    let workBucketID = work.inboxBucket?.persistentModelID
    let foreignBucket = extra.inboxBucket
    let survivingLists = extra.listsArray.filter {
        $0.persistentModelID != foreignBucket?.persistentModelID
    }

    // Step 3a — move the foreign bucket's tasks into Work's bucket, then drop the bucket.
    var taskCount = 0
    if let foreignBucket,
       foreignBucket.persistentModelID != workBucketID,
       let workBucket = work.inboxBucket {
        taskCount = foreignBucket.remindersArray.count
        for task in foreignBucket.remindersArray {
            task.reminderList = workBucket
        }
        modelContext.delete(foreignBucket)
    }

    // Step 3b — reparent the remaining lists into Work and clear their sort order so the
    // backfill re-ranks them deterministically instead of interleaving with Personal's.
    for list in survivingLists {
        list.group = work
        list.sortOrder = nil
    }

    // Step 3c — the area now holds no lists, so deleting it cannot orphan anything.
    modelContext.delete(extra)
    return (survivingLists.count, taskCount)
}

// MARK: - Capture resolution

/// The Inbox bucket of a specific area, addressed by pointer. Seeds the locked areas when
/// the store is still empty. Never falls back to a positionally-first area.
@MainActor
@discardableResult
func resolveAreaBucket(
    for areaID: ReminderListGroup.ID?,
    in modelContext: ModelContext
) -> ReminderList {
    if let areas = reconcileLockedAreas(in: modelContext) {
        if let areaID, let match = [areas.work, areas.personal].first(where: {
            $0.persistentModelID == areaID
        }) {
            return match.inboxBucket ?? makeBucket(for: match, in: modelContext)
        }
        return areas.work.inboxBucket ?? makeBucket(for: areas.work, in: modelContext)
    }

    _ = seedDefaultAreas(in: modelContext)
    guard let work = orderedGroups(in: modelContext).first(where: { $0.name == AreaNames.work }) else {
        return makeBucket(for: ReminderListGroup(name: AreaNames.work), in: modelContext)
    }
    return work.inboxBucket ?? makeBucket(for: work, in: modelContext)
}
