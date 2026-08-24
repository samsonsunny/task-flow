# list-management

## Purpose

Define CRUD and ordering operations on lists themselves: rename via context menu, delete with explicit cascade semantics, and drag-to-reorder using the shared fractional-string sort order.

Consolidates (2026-08): `list-delete`, `list-rename`, `list-reorder`.

## Requirements

### Requirement: User can rename any unprotected list via context menu
The system SHALL allow users to rename any list that is not the protected "Reminders" list. Renaming SHALL be initiated via a context menu on the list row in `ListsTabView`. The protected "Reminders" list SHALL NOT show a rename option in its context menu.

#### Scenario: Rename a custom list
- **WHEN** the user long-presses a list row (that is not "Reminders") in `ListsTabView`
- **THEN** the context menu SHALL display a "Rename" option

#### Scenario: Protected list has no rename option
- **WHEN** the user long-presses the "Reminders" list row in `ListsTabView`
- **THEN** the context menu SHALL NOT include a "Rename" option

### Requirement: Rename uses an alert with a text field
When the user taps "Rename" from the context menu, the system SHALL present an alert containing a text field pre-filled with the current list name. The user can edit the name and confirm or cancel.

#### Scenario: Rename with valid name
- **WHEN** the user edits the name in the alert text field and confirms
- **THEN** the list's `name` field SHALL be updated to the new value
- **AND** the new name SHALL be reflected immediately in `ListsTabView` and `ListDetailView` navigation titles

#### Scenario: Rename with empty name is rejected
- **WHEN** the user clears the name field and confirms
- **THEN** the system SHALL NOT update the list name
- **AND** the alert SHALL remain visible or dismiss without changes

#### Scenario: Cancel rename
- **WHEN** the user taps Cancel in the rename alert
- **THEN** the list name SHALL remain unchanged

### Requirement: User can delete any unprotected list via context menu
The system SHALL allow users to delete any list that is not the protected "Reminders" list. Deletion SHALL be initiated via a context menu on the list row in `ListsTabView`. The protected "Reminders" list SHALL NOT show a delete option in its context menu.

#### Scenario: Delete option appears in context menu
- **WHEN** the user long-presses a list row (that is not "Reminders") in `ListsTabView`
- **THEN** the context menu SHALL display a "Delete List" option

#### Scenario: Protected list has no delete option
- **WHEN** the user long-presses the "Reminders" list row in `ListsTabView`
- **THEN** the context menu SHALL NOT include a "Delete List" option

### Requirement: Delete shows confirmation with two cascade options
When the user taps "Delete List", the system SHALL present a confirmation alert with two explicit choices:
1. "Move tasks to Reminders" — re-parents all tasks to the default "Reminders" list, then deletes the list
2. "Delete All Tasks" — deletes all tasks in the list (cascade), then deletes the list

"Move tasks to Reminders" SHALL be the default (non-destructive) option. "Delete All Tasks" SHALL be visually styled as destructive.

#### Scenario: Move tasks to Reminders on delete
- **WHEN** the user taps "Move tasks to Reminders" in the delete confirmation
- **THEN** every task in the deleted list SHALL have its `reminderList` set to the "Reminders" list
- **AND** the list SHALL be deleted from the model context
- **AND** the tasks SHALL remain accessible in "Reminders" and any other views that reference them

#### Scenario: Cascade delete all tasks
- **WHEN** the user taps "Delete All Tasks" in the delete confirmation
- **THEN** every task in the deleted list SHALL be deleted from the model context
- **AND** the list SHALL be deleted from the model context
- **AND** all associated notifications for those tasks SHALL be cancelled

#### Scenario: Cancel delete
- **WHEN** the user taps Cancel in the delete confirmation
- **THEN** the list and its tasks SHALL remain unchanged

#### Scenario: Delete an empty list
- **WHEN** the user deletes a list that contains no tasks
- **THEN** the confirmation alert SHALL still appear with both options
- **AND** both options SHALL produce the same result: the list is deleted, no tasks are affected

### Requirement: Lists are reorderable via drag in ListsTabView
The system SHALL allow users to reorder all lists (including "Reminders") in `ListsTabView` by dragging rows. The reordered position SHALL persist across app restarts.

#### Scenario: Drag reorders a single list
- **WHEN** the user long-presses and drags a list row to a new position in `ListsTabView`
- **THEN** the list SHALL appear at the dropped position
- **AND** all other lists SHALL remain in their relative positions
- **AND** the new order SHALL persist after relaunching the app

#### Scenario: "Reminders" list is reorderable
- **WHEN** the user drags the "Reminders" list to a new position
- **THEN** "Reminders" SHALL appear at the dropped position
- **AND** is NOT pinned to the top of the list

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
- **THEN** the list SHALL appear as the last item in `ListsTabView`
- **AND** all existing list positions SHALL remain unchanged

### Requirement: Existing lists backfilled on migration
On first launch after the update, all existing `ReminderList` entries without a `sortOrder` SHALL receive an initial sortOrder based on their current display order ("Reminders" first, then alphabetical by name).

#### Scenario: Existing lists get sequential sortOrder
- **WHEN** the app launches after the update
- **THEN** every existing `ReminderList` SHALL have a non-nil `sortOrder`
- **AND** sortOrder values SHALL respect the original display order (Reminders first, then alphabetical)
