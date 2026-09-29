# list-management

## Purpose

Define CRUD and ordering operations on lists themselves: rename via context menu, delete with explicit cascade semantics, and drag-to-reorder using the shared fractional-string sort order.

Consolidates (2026-08): `list-delete`, `list-rename`, `list-reorder`.

## MODIFIED Requirements

### Requirement: User can rename any unprotected list via context menu

The system SHALL allow users to rename any list that is not an area's Inbox bucket. A list SHALL be identified as a protected bucket by pointer (`list == list.group?.defaultList`), never by name. Inbox buckets SHALL NOT show a rename option in their context menu. Renaming a list SHALL NOT alter its parent area's name or lock state, so lists inside locked areas remain renameable.

#### Scenario: Rename a custom list
- **WHEN** the user long-presses a list row that is not an Inbox bucket on Home
- **THEN** the context menu SHALL display a "Rename" option

#### Scenario: Inbox bucket has no rename option
- **WHEN** the user long-presses an area's Inbox bucket row on Home
- **THEN** the context menu SHALL NOT include a "Rename" option

#### Scenario: Renaming a list does not affect its area
- **WHEN** the user renames a list inside the locked Work area
- **THEN** the list SHALL be renamed
- **AND** the Work area SHALL remain named "Work" and `isLocked == true`

### Requirement: User can delete any unprotected list via context menu

The system SHALL allow users to delete any list that is not an area's Inbox bucket, identified by pointer (`list == list.group?.defaultList`). Inbox buckets SHALL NOT show a delete option in their context menu. A list SHALL NOT be deletable if it is the last remaining list in its area, because every area must always retain a bucket.

#### Scenario: Delete option appears in context menu
- **WHEN** the user long-presses a list row that is not an Inbox bucket on Home
- **THEN** the context menu SHALL display a "Delete List" option

#### Scenario: Inbox bucket has no delete option
- **WHEN** the user long-presses an area's Inbox bucket row on Home
- **THEN** the context menu SHALL NOT include a "Delete List" option

#### Scenario: Last non-bucket list may still be deleted
- **WHEN** an area contains only its bucket and one custom list
- **AND** the user deletes the custom list
- **THEN** the custom list and its tasks SHALL be deleted per the cascade rules
- **AND** the area's bucket SHALL remain

### Requirement: Delete shows confirmation with two cascade options

When the user taps "Delete List", the system SHALL present a confirmation alert with two explicit choices:
1. "Move tasks to Inbox" — re-parents all tasks to the *owning area's* Inbox bucket, then deletes the list
2. "Delete All Tasks" — deletes all tasks in the list (cascade), then deletes the list

"Move tasks to Inbox" SHALL be the default (non-destructive) option. "Delete All Tasks" SHALL be visually styled as destructive. Neither option SHALL delete the parent area.

#### Scenario: Move tasks to Inbox on delete
- **WHEN** the user taps "Move tasks to Inbox" in the delete confirmation
- **THEN** every task in the deleted list SHALL have its `reminderList` set to the list's owning area's Inbox bucket
- **AND** the list SHALL be deleted from the model context
- **AND** the owning area SHALL survive with its bucket intact

#### Scenario: Cascade delete all tasks
- **WHEN** the user taps "Delete All Tasks" in the delete confirmation
- **THEN** every task in the deleted list SHALL be deleted from the model context
- **AND** the list SHALL be deleted from the model context
- **AND** all associated notifications for those tasks SHALL be cancelled

#### Scenario: Cancel delete
- **WHEN** the user taps Cancel in the delete confirmation
- **THEN** the list and its tasks SHALL remain unchanged

#### Scenario: Deleting a list never removes its area
- **WHEN** the user deletes the last custom list in an area
- **THEN** the area SHALL still exist
- **AND** SHALL remain locked
- **AND** SHALL still own its bucket

### Requirement: Lists are reorderable via drag in ListsTabView

The system SHALL allow users to reorder lists within the selected area by dragging their Home section headers. Reordered positions SHALL persist across app restarts. An area's Inbox bucket SHALL remain pinned as the first section and SHALL NOT be draggable; all other lists in that area SHALL be reorderable. Reordering SHALL NOT move a list between areas.

#### Scenario: Drag reorders a member list
- **WHEN** the user long-presses and drags a list section header to a new position within the same area (below the bucket)
- **THEN** the list SHALL appear at the dropped position
- **AND** the bucket SHALL remain first

#### Scenario: Bucket is not draggable
- **WHEN** the user attempts to drag an area's Inbox bucket section
- **THEN** the bucket SHALL remain the first section of its area

#### Scenario: Drag does not cross areas
- **WHEN** the user drags a list while a different area is not selected
- **THEN** the list SHALL remain in its own area
- **AND** no other area's sections SHALL be offered as drop targets

### Requirement: New lists append to end

When a list is created, the system SHALL assign it a sortOrder that places it after all existing lists in its area, and SHALL place it in the selected area.

#### Scenario: New list appears at bottom
- **WHEN** a user creates a new list in the selected area
- **THEN** the list SHALL appear as the last section on Home
- **AND** all existing list positions SHALL remain unchanged

#### Scenario: New list lands in the selected area only
- **WHEN** a user creates a list with Work selected
- **THEN** the list SHALL belong to Work
- **AND** SHALL NOT appear when Personal is selected
