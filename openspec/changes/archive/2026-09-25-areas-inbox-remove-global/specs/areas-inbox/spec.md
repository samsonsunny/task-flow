## ADDED Requirements

### Requirement: Every group owns an Inbox bucket identified by pointer

Each `ReminderListGroup` SHALL own exactly one Inbox bucket — a `ReminderList` named "Inbox" that resides inside that group and is referenced by a pointer (`group.defaultList`), never by name. The bucket SHALL be created when a group is created and SHALL be a real, visible list within the group's section. The bucket SHALL display an inbox tray icon and SHALL be pinned as the first list within its group.

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

### Requirement: Inbox bucket is protected in v1

The Inbox bucket of a group SHALL be protected in this change: it SHALL NOT be renamable, deletable, or movable to another group or to an ungrouped state. Context menus and edit flows for the bucket SHALL NOT offer rename, delete, or move-to-group actions.

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

### Requirement: Migration reparents the global Inbox into the first group

On the first launch after the update, the existing global "Inbox" list SHALL be reparented into the first group as that group's Inbox bucket. The list object itself SHALL be reused — its `group` is set to the first group and the first group's `defaultList` is set to it. No `TaskItem` SHALL be modified, moved, or deleted; every task (completed or not) SHALL remain in its list with all dates, flags, and sort order preserved.

#### Scenario: Groups exist — global Inbox becomes first group's bucket

- **WHEN** the app launches after the update with existing groups and a global "Inbox" list
- **THEN** the global Inbox list SHALL have its `group` set to the first group (lowest `sortOrder`, then earliest `createdAt`)
- **AND** the first group's `defaultList` SHALL point to it
- **AND** all tasks originally in the global Inbox SHALL remain in the same list, unmodified

#### Scenario: Empty store — default Work and Personal areas are seeded

- **WHEN** the app launches after the update and no groups exist in the store
- **THEN** the system SHALL create "Work" and "Personal" groups, each with an Inbox bucket
- **AND** the reparented global Inbox SHALL become the Work group's bucket
- **AND** Personal SHALL have its own empty Inbox bucket

#### Scenario: Legacy ungrouped lists reparent into the first group

- **WHEN** the app launches after the update and lists with `group == nil` exist
- **THEN** those lists SHALL be reparented into the first group
- **AND** their tasks SHALL remain in place with no per-task modification

#### Scenario: Migration runs once and is idempotent

- **WHEN** the migration completes successfully and the app is relaunched
- **THEN** the migration SHALL NOT re-run
- **AND** if re-run against the migrated store, it SHALL be a no-op

#### Scenario: No task data is ever deleted

- **WHEN** the migration executes
- **THEN** no `TaskItem` SHALL be deleted, moved across lists, or have any property modified

### Requirement: Reconciler sweeps area-less tasks to the first group's bucket

On each launch, the area reconciler SHALL ensure every group has an Inbox bucket and no task is stranded without a list. Any `TaskItem` with `reminderList == nil` (e.g., referencing a deleted list) SHALL be assigned to the first group's Inbox bucket.

#### Scenario: Nil-list tasks land in first group's bucket

- **WHEN** a `TaskItem` exists with `reminderList == nil`
- **THEN** the reconciler SHALL set its `reminderList` to the first group's Inbox bucket
- **AND** the task SHALL NOT be created in a fresh side-effect list

#### Scenario: Missing bucket is recreated

- **WHEN** a group exists without a `defaultList` (sync divergence, partial failure)
- **THEN** the reconciler SHALL create an Inbox bucket for that group and set the pointer