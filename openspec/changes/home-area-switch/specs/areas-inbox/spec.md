# areas-inbox Specification

## Purpose

TBD - created by archiving change areas-inbox-remove-global. Update Purpose after archive.

## MODIFIED Requirements

### Requirement: Every group owns an Inbox bucket identified by pointer

Each `ReminderListGroup` SHALL own exactly one Inbox bucket — a `ReminderList` named "Inbox" that resides inside that group and is referenced by a pointer (`group.defaultList`), never by name. The bucket SHALL be created when a group is created and SHALL be a real, visible list within the group's section. The bucket SHALL display an inbox tray icon and SHALL be pinned as the first list within its group.

The store SHALL contain exactly two groups — Work and Personal — and each SHALL own its own distinct bucket. A bucket SHALL never be shared between groups, and no bucket SHALL be reparented into a group whose `defaultList` already points elsewhere.

#### Scenario: Group has an Inbox bucket on creation
- **WHEN** a `ReminderListGroup` is created through any flow
- **THEN** a `ReminderList` named "Inbox" SHALL be created as a member of that group
- **AND** the group's `defaultList` pointer SHALL reference that list
- **AND** the bucket SHALL be the first list shown in the group section

#### Scenario: Bucket identity is by pointer, not name
- **WHEN** a user has multiple groups, each with an Inbox bucket
- **THEN** each group SHALL reference its own bucket via `defaultList`
- **AND** no code SHALL locate a bucket by comparing `name == "Inbox"`

#### Scenario: Detached Inbox list is reconciled
- **WHEN** an `Inbox` list exists with `group == nil` (legacy global Inbox or sync divergence)
- **THEN** the reconciler SHALL reparent it into the first group as that group's bucket
- **AND** set the first group's `defaultList` to it

#### Scenario: Both locked areas own distinct buckets
- **WHEN** the store has been reconciled to exactly two locked areas
- **THEN** Work and Personal SHALL each own a bucket
- **AND** the two buckets SHALL be different `ReminderList` objects

### Requirement: Inbox bucket is protected in v1

The Inbox bucket of a group SHALL be protected: it SHALL NOT be renamable, deletable, or movable to another group or to an ungrouped state. Context menus and edit flows for the bucket SHALL NOT offer rename, delete, or move-to-group actions. The bucket's protection is independent of its parent area's lock state, and a bucket inside a locked area is protected by both rules.

#### Scenario: Cannot rename a bucket
- **WHEN** the user opens the context menu on a group's Inbox bucket
- **THEN** no "Rename" option SHALL be offered

#### Scenario: Cannot delete a bucket
- **WHEN** the user opens the context menu on a group's Inbox bucket
- **THEN** no "Delete" option SHALL be offered

#### Scenario: Cannot move a bucket out of its group
- **WHEN** the user opens the context menu on a group's Inbox bucket
- **THEN** no "Move to Group" option SHALL be offered
- **AND** the bucket SHALL remain a member of its owning group

### Requirement: Reconciler sweeps area-less tasks to the first group's bucket

On each launch, the area reconciler SHALL ensure every group has an Inbox bucket and no task is stranded without a list. Any `TaskItem` with `reminderList == nil` (e.g., referencing a deleted list) SHALL be assigned to the Work area's Inbox bucket. Where no Work area exists yet, the resolver SHALL seed Work and Personal and target Work's bucket.

#### Scenario: Nil-list tasks land in Work's bucket
- **WHEN** a `TaskItem` exists with `reminderList == nil`
- **THEN** the reconciler SHALL set its `reminderList` to the Work area's Inbox bucket
- **AND** the task SHALL NOT be created in a fresh side-effect list

#### Scenario: Missing bucket is recreated
- **WHEN** a group exists without a `defaultList` (sync divergence, partial failure)
- **THEN** the reconciler SHALL create an Inbox bucket for that group and set the pointer

#### Scenario: Sweep target follows Work, not list position
- **WHEN** Personal sorts before Work
- **AND** a task has `reminderList == nil`
- **THEN** the task SHALL be assigned to Work's Inbox bucket
- **AND** SHALL NOT be assigned to the bucket of the first-sorted group

## ADDED Requirements

### Requirement: The locked-area reconciler is recurring and separate from the one-time migration

Two distinct mechanisms SHALL exist. The one-time global-Inbox migration is a historical, flag-gated event and SHALL remain as previously specified. The locked-area reconciler SHALL be a separate, recurring pass that runs on every launch, is gated by no persisted flag, and is idempotent. The recurring reconciler SHALL run before the one-time migration's outcome is depended upon by any view, so that the two never race on group identity.

The recurring reconciler SHALL compose with the area-less sweep and the bucket backfill: it SHALL first establish exactly two locked areas, then sweep nil-list tasks and recreate missing buckets, then re-merge any extra areas.

#### Scenario: Recurring reconciler is not flag-gated
- **WHEN** the app launches and the one-time migration flag is already set
- **THEN** the locked-area reconciler SHALL still run
- **AND** it SHALL rely on no separate persisted marker

#### Scenario: Reconciler is idempotent
- **WHEN** the locked-area reconciler runs repeatedly against an already-conforming store
- **THEN** each run SHALL be a no-op
- **AND** the store SHALL remain exactly two locked areas with one task-preserving merge pass

#### Scenario: Reconciler restores conformance after divergence
- **WHEN** an unlocked third group appears via CloudKit sync
- **THEN** the next launch's reconciler SHALL merge its lists into Work
- **AND** the store SHALL again contain exactly two locked areas

### Requirement: Foreign buckets are merged, never reparented into another area

When an area other than Work and Personal is merged away, its Inbox bucket SHALL NOT be reparented into Work. The bucket's tasks SHALL be repointed to Work's own bucket and the emptied bucket SHALL be deleted, so that Work retains exactly one bucket and no stale `defaultForGroup` pointer survives the merge.

#### Scenario: Foreign bucket tasks move and bucket is deleted
- **WHEN** a third area's bucket contains tasks
- **THEN** each of those tasks SHALL have its `reminderList` set to Work's bucket
- **AND** the third area's bucket SHALL be deleted
- **AND** Work SHALL still own exactly one bucket

#### Scenario: Work never ends with two buckets
- **WHEN** the merge completes
- **THEN** Work's `defaultList` SHALL point at exactly one `ReminderList`
- **AND** no other list inside Work SHALL have `group.defaultForGroup` pointing at it

#### Scenario: Merge preserves every task object
- **WHEN** a foreign bucket's tasks are merged into Work's bucket
- **THEN** the same `TaskItem` objects SHALL persist
- **AND** their title, `dueDate`, `isCompleted`, `completionDate`, notes, and priority SHALL be unchanged
