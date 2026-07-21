## ADDED Requirements

### Requirement: Date action in bottom toolbar

The bottom toolbar SHALL include a Date action (calendar icon) that opens a submenu with rescheduling options: Today, Tomorrow, Next Week, Later, and Pick Date.

#### Scenario: Date submenu shows rescheduling options

- **WHEN** the user taps the Date button in the bottom toolbar
- **THEN** a submenu SHALL appear with options: Today, Tomorrow, Next Week, Later, Pick Date

#### Scenario: Reschedule applies to all selected tasks

- **WHEN** the user selects "Today" from the Date submenu
- **AND** 3 tasks are selected
- **THEN** all 3 tasks SHALL have their due date set to today
- **AND** the selection mode SHALL remain active

#### Scenario: Pick Date opens date picker

- **WHEN** the user selects "Pick Date..." from the Date submenu
- **THEN** the TaskScheduleDatePickerSheet SHALL open
- **AND** the selected date SHALL apply to all selected tasks

### Requirement: Move action in bottom toolbar

The bottom toolbar SHALL include a Move action (folder icon) that opens a submenu listing all available reminder lists.

#### Scenario: Move submenu shows all lists

- **WHEN** the user taps the Move button in the bottom toolbar
- **THEN** a submenu SHALL appear listing all available reminder lists grouped by section

#### Scenario: Move applies to all selected tasks

- **WHEN** the user selects a list from the Move submenu
- **AND** 3 tasks are selected
- **THEN** all 3 tasks SHALL be moved to the selected list
- **AND** the selection mode SHALL remain active

### Requirement: Tag action in bottom toolbar

The bottom toolbar SHALL include a Tag action (tag icon) that opens a submenu with Priority options (Low, Medium, High, None) and an Add Tag option.

#### Scenario: Tag submenu shows priority and tag options

- **WHEN** the user taps the Tag button in the bottom toolbar
- **THEN** a submenu SHALL appear with Priority options (Low, Medium, High, None), a divider, and "Add Tag..."

#### Scenario: Priority applies to all selected tasks

- **WHEN** the user selects a priority level from the Tag submenu
- **AND** 3 tasks are selected
- **THEN** all 3 tasks SHALL have their priority set to the selected level
- **AND** the selection mode SHALL remain active

#### Scenario: Add Tag opens tag picker

- **WHEN** the user selects "Add Tag..." from the Tag submenu
- **THEN** a tag picker interface SHALL appear
- **AND** the selected tag SHALL be applied to all selected tasks

### Requirement: Complete action in bottom toolbar

The bottom toolbar SHALL include a Complete action (checkmark icon) that toggles completion for all selected tasks. The action label SHALL adapt based on the completion state of selected tasks.

#### Scenario: Mark Complete when any task is incomplete

- **WHEN** the user taps the Complete button
- **AND** at least one selected task is incomplete
- **THEN** all selected tasks SHALL be marked as complete
- **AND** the selection mode SHALL remain active

#### Scenario: Mark Incomplete when all tasks are complete

- **WHEN** the user taps the Complete button
- **AND** all selected tasks are complete
- **THEN** all selected tasks SHALL be marked as incomplete
- **AND** the selection mode SHALL remain active

### Requirement: Delete action in bottom toolbar

The bottom toolbar SHALL include a Delete action (trash icon) that shows a confirmation alert before deleting all selected tasks.

#### Scenario: Delete shows confirmation alert

- **WHEN** the user taps the Delete button
- **THEN** a confirmation alert SHALL appear
- **AND** the alert SHALL display the number of tasks to be deleted
- **AND** the alert SHALL have "Cancel" and "Delete" buttons
- **AND** the "Delete" button SHALL be styled as destructive (red)

#### Scenario: Confirm delete removes all selected tasks

- **WHEN** the user confirms deletion in the alert
- **AND** 3 tasks are selected
- **THEN** all 3 tasks SHALL be deleted
- **AND** selection mode SHALL exit

#### Scenario: Cancel delete keeps selection

- **WHEN** the user taps "Cancel" in the confirmation alert
- **THEN** no tasks SHALL be deleted
- **AND** selection mode SHALL remain active with tasks still selected

### Requirement: Selection count displayed in toolbar

The bottom toolbar SHALL display the number of selected items as text (e.g., "3 selected") centered below the action buttons.

#### Scenario: Count shows zero when no selection

- **WHEN** the user is in selection mode
- **AND** no tasks are selected
- **THEN** the toolbar SHALL display "0 selected"

#### Scenario: Count updates on selection change

- **WHEN** the user selects a task
- **THEN** the count SHALL increment by 1

#### Scenario: Count updates on deselection

- **WHEN** the user deselects a task
- **THEN** the count SHALL decrement by 1

### Requirement: Bulk operations use existing ViewModel methods

Each bulk operation SHALL call the existing single-task ViewModel method in a loop over all selected tasks. The ViewModel's `update()` method SHALL be called once after all mutations complete, not per-task.

#### Scenario: Bulk delete loops over existing delete method

- **WHEN** a bulk delete is executed on selected tasks
- **THEN** the existing `delete(task:)` ViewModel method SHALL be called for each selected task
- **AND** `update()` SHALL be called once after all deletions

#### Scenario: Bulk reschedule loops over existing reschedule method

- **WHEN** a bulk reschedule is executed on selected tasks
- **THEN** the existing reschedule ViewModel method SHALL be called for each selected task
- **AND** `update()` SHALL be called once after all reschedules

#### Scenario: Bulk move loops over existing move method

- **WHEN** a bulk move is executed on selected tasks
- **THEN** the existing `moveTask(_:to:)` ViewModel method SHALL be called for each selected task
- **AND** `update()` SHALL be called once after all moves

### Requirement: Actions remain available after operations

After performing a bulk operation, selection mode SHALL remain active and the selected tasks SHALL remain selected (unless they were deleted). This allows chaining multiple operations.

#### Scenario: Selection persists after reschedule

- **WHEN** the user reschedules 3 selected tasks to Tomorrow
- **THEN** selection mode SHALL remain active
- **AND** the 3 tasks SHALL remain selected

#### Scenario: Selection clears after delete

- **WHEN** the user deletes 3 selected tasks
- **THEN** selection mode SHALL exit
- **AND** the selection SHALL be cleared

### Requirement: Drag-drop disabled in ListDetailView during selection

In ListDetailView, drag-drop reordering and nesting SHALL be disabled while in selection mode.

#### Scenario: Drag-drop disabled during selection

- **WHEN** the user is in selection mode in ListDetailView
- **AND** attempts to drag a task row
- **THEN** no drag interaction SHALL occur
