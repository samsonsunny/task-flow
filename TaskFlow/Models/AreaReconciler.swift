import Foundation
import SwiftData

/// Canonical names that the whole app keys off.
///
/// The locked-area flags and the bucket link are derived from these strings rather than
/// persisted, because the CloudKit production schema for `ReminderListGroup` and
/// `ReminderList` is sealed: a new column on either record makes every mirroring export
/// abort. `reconcileLockedAreas(in:)` runs on every launch and guarantees the two locked
/// names exist, each owning one list named `inbox`; every other group is a user-created
/// project and is preserved. The canonical names are therefore a sound key.
enum AreaNames {
    static let work = "Work"
    static let personal = "Personal"
    static let inbox = "Inbox"
}

/// Customer-facing area label. The Personal area is presented as Home, while the stored
/// name stays "Personal" so area resolution, reconciliation, and CloudKit data are untouched.
func areaDisplayName(_ name: String) -> String {
    name == AreaNames.personal ? "Home" : name
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
/// what the pass actually did rather than only on the resulting shape.
struct LockedAreaState {
    var work: ReminderListGroup
    var personal: ReminderListGroup
}

// MARK: - Recurring locked-area reconciler

/// Ensures Work and Personal exist, each owning its own Inbox bucket, and that every area
/// (including user-created projects) owns a bucket and every list/task is filed.
///
/// Runs on every launch. Work and Personal are still normalized by name, but other groups
/// are user-created projects and are preserved rather than merged away. The pass is
/// idempotent — a second run against a conforming store changes nothing.
@MainActor
@discardableResult
func reconcileLockedAreas(in modelContext: ModelContext) -> LockedAreaState? {
    let state = resolveLockedAreas(in: modelContext)
    guard let work = state?.work, let personal = state?.personal else { return nil }

    // Every area — locked or user-created — must own its own Inbox bucket. `inboxBucket`
    // only returns a list that is already inside the area, so a missing bucket is the same
    // condition as a stolen one.
    for group in orderedGroups(in: modelContext) where group.inboxBucket == nil {
        makeBucket(for: group, in: modelContext)
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

    // Rank any list the orphan sweep reparented, then sweep any other unranked list. The
    // non-saving variant matters: this pass must commit as one save, not a backfill save
    // followed by a second save.
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
