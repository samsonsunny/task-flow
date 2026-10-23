# areas-inbox

## Purpose

Define the per-domain Inbox buckets, the Work/Personal seeding invariant, and the launch reconciler that enforces exactly two domains without losing user data.

## Requirements

### Requirement: Each domain owns exactly one Inbox bucket

Work and Personal SHALL each own exactly one Inbox bucket: a real, visible `ReminderList` named `Inbox` that belongs to that domain. There SHALL be no global Inbox and no second bucket inside a domain.

Bucket identity SHALL be derived from the owning domain and the canonical `Inbox` name, not from a persisted pointer. No `defaultList`, `defaultForGroup`, or equivalent CloudKit-mirrored field SHALL be added.

#### Scenario: Each domain has one bucket

- **WHEN** the app launches
- **THEN** Work SHALL have exactly one list named `Inbox`
- **AND** Personal SHALL have exactly one list named `Inbox`
- **AND** each bucket SHALL belong to its domain

#### Scenario: Identity is not persisted by pointer

- **WHEN** code resolves a domain's bucket
- **THEN** it SHALL use domain membership plus the canonical name
- **AND** it SHALL NOT require a new stored relationship

### Requirement: Inbox bucket is protected

Work's and Personal's Inbox buckets SHALL be protected: no rename, delete, or move action SHALL be offered, and dragging SHALL NOT move them. They SHALL remain pinned first in their domain's list section.

#### Scenario: Cannot rename a locked bucket

- **WHEN** the user swipes Work Inbox
- **THEN** no rename action SHALL be offered

#### Scenario: Cannot delete a locked bucket

- **WHEN** the user swipes Personal Inbox
- **THEN** no delete action SHALL be offered

### Requirement: Capture defaults to the active domain's bucket

When a task is created without an explicit project/list, it SHALL land in the active domain's Inbox bucket. On surfaces with no domain context, the default SHALL be Work Inbox.

#### Scenario: Work capture

- **WHEN** the user creates a task from Work without selecting a project
- **THEN** `reminderList` SHALL be Work Inbox

#### Scenario: Personal capture

- **WHEN** the user creates a task from Personal without selecting a project
- **THEN** `reminderList` SHALL be Personal Inbox

#### Scenario: No active domain

- **WHEN** the user captures from Today or another surface with no domain/list context
- **THEN** `reminderList` SHALL default to Work Inbox

### Requirement: Launch reconciler enforces the two-domain invariant

On every launch, before views read area state, the reconciler SHALL:

1. Adopt or seed exactly one Work and one Personal domain.
2. Normalize their stored names to `Work` and `Personal`.
3. Fold every extra `ReminderListGroup` into Work.
4. Ensure Work and Personal each own an Inbox bucket.
5. Assign every ungrouped list to Work.
6. Assign every list-less task to Work Inbox.
7. Save the whole pass once.

The pass SHALL be idempotent: a second run against a conforming store SHALL change nothing.

#### Scenario: Empty store is seeded

- **WHEN** the app launches with no domains
- **THEN** Work and Personal SHALL be created
- **AND** each SHALL receive an Inbox bucket

#### Scenario: Extra domain is folded without data loss

- **WHEN** a third `ReminderListGroup` exists
- **THEN** its non-bucket lists SHALL be reparented to Work
- **AND** its bucket's tasks SHALL be repointed to Work Inbox
- **AND** its now-empty bucket and group record SHALL be deleted
- **AND** no `TaskItem` SHALL be deleted

#### Scenario: Orphan list is adopted

- **WHEN** a list has `group == nil`
- **THEN** it SHALL be assigned to Work
- **AND** its tasks SHALL remain in it

#### Scenario: Orphan task is adopted

- **WHEN** a task has `reminderList == nil`
- **THEN** it SHALL be assigned to Work Inbox
- **AND** no new side-effect list SHALL be created

#### Scenario: Missing bucket is repaired

- **WHEN** Work or Personal has no `Inbox` list
- **THEN** the reconciler SHALL create one inside that domain

#### Scenario: Pass is idempotent

- **WHEN** the reconciler runs twice against a conforming store
- **THEN** the second pass SHALL make no changes

### Requirement: Migration preserves every task

The one-time legacy migration and recurring reconciler SHALL NOT delete tasks or reset task content. Moving a legacy global Inbox or a foreign domain's bucket SHALL only change `TaskItem.reminderList`; dates, completion, flags, notes, subtasks, and sort order SHALL be preserved.

#### Scenario: Global Inbox is folded into Work

- **WHEN** a legacy ungrouped `Inbox` list exists
- **THEN** its tasks SHALL move to Work Inbox
- **AND** the duplicate list SHALL be removed
- **AND** the task objects SHALL otherwise be unchanged

#### Scenario: No task content changes during reconciliation

- **WHEN** the reconciler reparents lists or tasks
- **THEN** it SHALL NOT modify task titles, notes, dates, completion, flags, priority, subtasks, or tags
