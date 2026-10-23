# list-management

## Purpose

Define CRUD and ordering operations on lists themselves: rename via context menu, delete with explicit cascade semantics, and drag-to-reorder using the shared fractional-string sort order.

Consolidates (2026-08): `list-delete`, `list-rename`, `list-reorder`.
## Requirements
### Requirement: User can rename any unprotected list via context menu

The system SHALL allow users to rename any list that is not an area's Inbox bucket. A list SHALL be identified as a protected bucket by its owning domain plus the canonical `Inbox` name (derived; see `areas-inbox`). Inbox buckets SHALL NOT show a rename option in their context menu.

#### Scenario: Rename a custom list

- **WHEN** the user long-presses a list row that is not an Inbox bucket in the list management surface
- **THEN** the context menu SHALL display a "Rename" option

#### Scenario: Inbox bucket has no rename option

- **WHEN** the user long-presses an area's Inbox bucket row in the list management surface
- **THEN** the context menu SHALL NOT include a "Rename" option

### Requirement: Rename uses an alert with a text field
When the user taps "Rename" from the context menu, the system SHALL present an alert containing a text field pre-filled with the current list name. The user can edit the name and confirm or cancel.

#### Scenario: Rename with valid name
- **WHEN** the user edits the name in the alert text field and confirms
- **THEN** the list's `name` field SHALL be updated to the new value
- **AND** the new name SHALL be reflected immediately in the list management surface and `ListDetailView` navigation titles

#### Scenario: Rename with empty name is rejected
- **WHEN** the user clears the name field and confirms
- **THEN** the system SHALL NOT update the list name
- **AND** the alert SHALL remain visible or dismiss without changes

#### Scenario: Cancel rename
- **WHEN** the user taps Cancel in the rename alert
- **THEN** the list name SHALL remain unchanged

### Requirement: User can delete any unprotected list via context menu

The system SHALL allow users to delete any list that is not an area's Inbox bucket, identified by its owning domain plus the canonical `Inbox` name. Inbox buckets SHALL NOT show a delete option in their context menu.

#### Scenario: Delete option appears in context menu

- **WHEN** the user long-presses a list row that is not an Inbox bucket in the list management surface
- **THEN** the context menu SHALL display a "Delete List" option

#### Scenario: Inbox bucket has no delete option

- **WHEN** the user long-presses an area's Inbox bucket row in the list management surface
- **THEN** the context menu SHALL NOT include a "Delete List" option

### Requirement: Delete shows confirmation with two cascade options

When the user taps "Delete List", the system SHALL present a confirmation alert with two explicit choices:
1. "Move tasks to Inbox" — re-parents all tasks to the *owning group's* Inbox bucket, then deletes the list
2. "Delete All Tasks" — deletes all tasks in the list (cascade), then deletes the list

"Move tasks to Inbox" SHALL be the default (non-destructive) option. "Delete All Tasks" SHALL be visually styled as destructive.

#### Scenario: Move tasks to Inbox on delete

- **WHEN** the user taps "Move tasks to Inbox" in the delete confirmation
- **THEN** every task in the deleted list SHALL have its `reminderList` set to the list's group's Inbox bucket (or Work Inbox if the list has no group)
- **AND** the list SHALL be deleted from the model context

#### Scenario: Cascade delete all tasks

- **WHEN** the user taps "Delete All Tasks" in the delete confirmation
- **THEN** every task in the deleted list SHALL be deleted from the model context
- **AND** the list SHALL be deleted from the model context
- **AND** all associated notifications for those tasks SHALL be cancelled

#### Scenario: Cancel delete

- **WHEN** the user taps Cancel in the delete confirmation
- **THEN** the list and its tasks SHALL remain unchanged

### Requirement: Lists are reorderable via drag in ListsTabView

The system SHALL allow users to reorder lists in the list management surface by dragging rows. Reordered positions SHALL persist across app restarts. A group's Inbox bucket SHALL remain pinned as the first list of its group and SHALL NOT be draggable; all other custom lists within the same domain SHALL be reorderable. Cross-domain moves SHALL NOT be supported.

#### Scenario: Drag reorders a member list

- **WHEN** the user long-presses and drags a member list row to a new position within its group (below the bucket)
- **THEN** the list SHALL appear at the dropped position
- **AND** the bucket SHALL remain first in the group

#### Scenario: Bucket is not draggable

- **WHEN** the user attempts to drag a group's Inbox bucket to another position
- **THEN** the bucket SHALL remain the first list of its group

### Requirement: List sort order uses fractional string encoding
The system SHALL store each list's position as a `String?` sortOrder using the same lexicographic midpoint algorithm used for task ordering. Only the dragged list's sortOrder SHALL be updated per drag operation.

#### Scenario: Single drag updates one record
- **WHEN** a list is dragged to a new position between two other lists
- **THEN** the system SHALL update only that list's `sortOrder` in the database
- **AND** SHALL NOT modify `sortOrder` on any other list

### Requirement: New lists append to end
When a list is created, the system SHALL assign it a sortOrder that places it after all existing lists.

#### Scenario: New list appears at bottom
- **WHEN** a user creates a new list
- **THEN** the list SHALL appear after existing custom lists in its domain
- **AND** all existing list positions SHALL remain unchanged

### Requirement: Existing lists backfilled on migration

On the first launch after the update, all existing `ReminderList` entries without a `sortOrder` SHALL receive an initial sortOrder based on their current display order. Each group's Inbox bucket SHALL receive the first sortOrder within its group; remaining lists SHALL be ordered alphabetically within their group, then sequentially by createdAt. The legacy "Inbox-first global" special case SHALL be removed.

#### Scenario: Existing lists get sequential sortOrder

- **WHEN** the app launches after the update
- **THEN** every existing `ReminderList` SHALL have a non-nil `sortOrder`
- **AND** each group's Inbox bucket SHALL sort before that group's other lists
- **AND** remaining lists SHALL follow in name-then-createdAt order within their group

