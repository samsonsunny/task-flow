## MODIFIED Requirements

### Requirement: User can rename any unprotected list via context menu

The system SHALL allow users to rename any list that is not an area's Inbox bucket. A list SHALL be identified as a protected bucket by pointer (`list == list.group?.defaultList`), never by name. Inbox buckets SHALL NOT show a rename option in their context menu.

#### Scenario: Rename a custom list

- **WHEN** the user long-presses a list row that is not an Inbox bucket in the sidebar
- **THEN** the context menu SHALL display a "Rename" option

#### Scenario: Inbox bucket has no rename option

- **WHEN** the user long-presses an area's Inbox bucket row in the sidebar
- **THEN** the context menu SHALL NOT include a "Rename" option

### Requirement: User can delete any unprotected list via context menu

The system SHALL allow users to delete any list that is not an area's Inbox bucket, identified by pointer (`list == list.group?.defaultList`). Inbox buckets SHALL NOT show a delete option in their context menu.

#### Scenario: Delete option appears in context menu

- **WHEN** the user long-presses a list row that is not an Inbox bucket in the sidebar
- **THEN** the context menu SHALL display a "Delete List" option

#### Scenario: Inbox bucket has no delete option

- **WHEN** the user long-presses an area's Inbox bucket row in the sidebar
- **THEN** the context menu SHALL NOT include a "Delete List" option

### Requirement: Delete shows confirmation with two cascade options

When the user taps "Delete List", the system SHALL present a confirmation alert with two explicit choices:
1. "Move tasks to Inbox" — re-parents all tasks to the *owning group's* Inbox bucket, then deletes the list
2. "Delete All Tasks" — deletes all tasks in the list (cascade), then deletes the list

"Move tasks to Inbox" SHALL be the default (non-destructive) option. "Delete All Tasks" SHALL be visually styled as destructive.

#### Scenario: Move tasks to Inbox on delete

- **WHEN** the user taps "Move tasks to Inbox" in the delete confirmation
- **THEN** every task in the deleted list SHALL have its `reminderList` set to the list's group's Inbox bucket (or the first group's bucket if the list has no group)
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

The system SHALL allow users to reorder lists in the sidebar by dragging rows. Reordered positions SHALL persist across app restarts. A group's Inbox bucket SHALL remain pinned as the first list of its group and SHALL NOT be draggable; all other lists (within their group, and across groups) SHALL be reorderable as before.

#### Scenario: Drag reorders a member list

- **WHEN** the user long-presses and drags a member list row to a new position within its group (below the bucket)
- **THEN** the list SHALL appear at the dropped position
- **AND** the bucket SHALL remain first in the group

#### Scenario: Bucket is not draggable

- **WHEN** the user attempts to drag a group's Inbox bucket to another position
- **THEN** the bucket SHALL remain the first list of its group

### Requirement: Existing lists backfilled on migration

On the first launch after the update, all existing `ReminderList` entries without a `sortOrder` SHALL receive an initial sortOrder based on their current display order. Each group's Inbox bucket SHALL receive the first sortOrder within its group; remaining lists SHALL be ordered alphabetically within their group, then sequentially by createdAt. The legacy "Inbox-first global" special case SHALL be removed.

#### Scenario: Existing lists get sequential sortOrder

- **WHEN** the app launches after the update
- **THEN** every existing `ReminderList` SHALL have a non-nil `sortOrder`
- **AND** each group's Inbox bucket SHALL sort before that group's other lists
- **AND** remaining lists SHALL follow in name-then-createdAt order within their group