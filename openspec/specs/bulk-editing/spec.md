# bulk-editing

## Purpose

Define multi-select mode on task list screens: entering/exiting selection, the visual affordances that replace normal row interactions, and the bottom toolbar's bulk actions (Date, Move, Tag, Complete, Delete).

Consolidates (2026-08): `bulk-selection`, `bulk-operations`.

## Requirements

### Requirement: Enter selection mode via ellipsis menu
The system SHALL provide a "Select Items" option as the first item in the ellipsis (⋯) toolbar menu on all task list screens. Tapping "Select Items" SHALL enter selection mode.

#### Scenario: Select Items appears in ellipsis menu on Today screen
- **WHEN** the user is on the Today screen
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item
- **AND** "Settings" SHALL appear below it

#### Scenario: Select Items appears in ellipsis menu on Tomorrow screen
- **WHEN** the user is on the Tomorrow screen
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

#### Scenario: Select Items appears in ellipsis menu on Upcoming screen
- **WHEN** the user is on the Upcoming screen
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

#### Scenario: Select Items appears in ellipsis menu on Later (Lists) screen
- **WHEN** the user is on the Later screen
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

#### Scenario: Select Items appears in ellipsis menu on ListDetailView
- **WHEN** the user is viewing a specific list (ListDetailView)
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

#### Scenario: Select Items appears in ellipsis menu on Completed screen
- **WHEN** the user is viewing the Completed screen
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

### Requirement: Exit selection mode via Done button
The system SHALL display a "Done" button in the top bar trailing position during selection mode. Tapping "Done" SHALL exit selection mode and clear all selections.

#### Scenario: Done replaces ellipsis during selection
- **WHEN** the user enters selection mode
- **THEN** the ellipsis menu SHALL be replaced by a "Done" text button in the top bar trailing position

#### Scenario: Done exits selection mode
- **WHEN** the user taps "Done" while in selection mode
- **THEN** selection mode SHALL exit
- **AND** all selected tasks SHALL be deselected
- **AND** the ellipsis menu SHALL return
- **AND** the bottom toolbar SHALL disappear

### Requirement: Selection circles replace completion circles
In selection mode, the system SHALL hide the completion circle and display a selection circle in its place. The selection circle SHALL be an empty circle (stroke only, no fill) when unselected, and a filled blue circle with white checkmark when selected.

#### Scenario: Unselected task shows empty circle
- **WHEN** the user is in selection mode
- **AND** a task is not selected
- **THEN** the task row SHALL display an empty circle (stroke only) on the left side
- **AND** the completion circle SHALL NOT be visible

#### Scenario: Selected task shows filled circle
- **WHEN** the user is in selection mode
- **AND** a task is selected
- **THEN** the task row SHALL display a filled blue circle with white checkmark on the left side

#### Scenario: Selection circles animate in on enter
- **WHEN** the user enters selection mode
- **THEN** selection circles SHALL animate into view (fade or slide from left)

#### Scenario: Completion circles return on exit
- **WHEN** the user exits selection mode
- **THEN** completion circles SHALL return to their normal state
- **AND** selection circles SHALL disappear

### Requirement: Tap toggles selection in selection mode
In selection mode, tapping anywhere on a task row (circle or row content) SHALL toggle that task's selection state. Tapping SHALL NOT open the task editor.

#### Scenario: Tap on unselected row selects it
- **WHEN** the user is in selection mode
- **AND** taps on an unselected task row
- **THEN** the task SHALL become selected
- **AND** the selection circle SHALL animate to filled state

#### Scenario: Tap on selected row deselects it
- **WHEN** the user is in selection mode
- **AND** taps on a selected task row
- **THEN** the task SHALL become deselected
- **AND** the selection circle SHALL animate to empty state

#### Scenario: Tap does not open editor
- **WHEN** the user is in selection mode
- **AND** taps on any task row
- **THEN** the task editor SHALL NOT be presented

### Requirement: Row tint on selection
Selected rows SHALL display a subtle blue background tint. The tint SHALL animate in and out with selection changes.

#### Scenario: Selected row has blue tint
- **WHEN** a task is selected in selection mode
- **THEN** the row background SHALL have a subtle blue tint

#### Scenario: Unselected row has no tint
- **WHEN** a task is not selected in selection mode
- **THEN** the row background SHALL have no tint (normal background)

#### Scenario: Deselecting removes tint
- **WHEN** a selected task is deselected
- **THEN** the blue tint SHALL animate out

### Requirement: Context menus disabled in selection mode
The system SHALL NOT display context menus on task rows while in selection mode.

#### Scenario: Long-press does nothing in selection mode
- **WHEN** the user is in selection mode
- **AND** long-presses a task row
- **THEN** no context menu SHALL appear

### Requirement: Swipe actions disabled in selection mode
The system SHALL NOT display swipe actions on task rows while in selection mode.

#### Scenario: Swipe does nothing in selection mode
- **WHEN** the user is in selection mode
- **AND** swipes on a task row
- **THEN** no swipe actions SHALL appear

### Requirement: Floating add button hidden in selection mode
The floating add button SHALL be hidden while in selection mode.

#### Scenario: FAB hidden during selection
- **WHEN** the user enters selection mode
- **THEN** the floating add button SHALL be hidden
- **AND** no hit testing SHALL occur on the hidden button

### Requirement: Subtasks auto-expand on enter
When entering selection mode, the system SHALL expand all collapsed subtask groups so all tasks are visible for selection.

#### Scenario: Collapsed subtasks expand on enter
- **WHEN** the user enters selection mode
- **AND** some parent tasks have collapsed subtasks
- **THEN** all subtask groups SHALL expand
- **AND** all subtasks SHALL be visible

#### Scenario: Collapse state restored on exit
- **WHEN** the user exits selection mode
- **THEN** the collapse state SHALL be restored to what it was before entering selection mode

### Requirement: Selection is independent per row
Each task row SHALL be independently selectable, including child/subtask rows. Selecting a parent SHALL NOT automatically select its children, and vice versa.

#### Scenario: Parent and child independently selectable
- **WHEN** the user is in selection mode
- **AND** selects a parent task
- **THEN** its child tasks SHALL NOT be selected

#### Scenario: Child selectable without parent
- **WHEN** the user is in selection mode
- **AND** selects a child task
- **THEN** the parent task SHALL NOT be selected

### Requirement: Bottom toolbar appears during selection
A bottom toolbar SHALL appear during selection mode containing bulk action buttons and a selection count. The toolbar SHALL animate in from the bottom.

#### Scenario: Toolbar appears on enter
- **WHEN** the user enters selection mode
- **THEN** a bottom toolbar SHALL slide up from the bottom of the screen
- **AND** the toolbar SHALL contain action buttons (Date, Move, Tag, Complete, Delete)
- **AND** the toolbar SHALL display the count of selected items

#### Scenario: Toolbar disappears on exit
- **WHEN** the user exits selection mode
- **THEN** the bottom toolbar SHALL slide down and disappear

#### Scenario: Selection count updates live
- **WHEN** the user selects or deselects tasks
- **THEN** the selection count in the toolbar SHALL update immediately

### Requirement: Quick capture disabled in selection mode
The quick capture row and inline capture functionality SHALL be disabled during selection mode.

#### Scenario: Quick capture not shown during selection
- **WHEN** the user is in selection mode
- **THEN** the quick capture row SHALL NOT be visible
- **AND** the FAB SHALL not trigger quick capture

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
