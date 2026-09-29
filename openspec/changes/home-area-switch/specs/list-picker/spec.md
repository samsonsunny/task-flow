## Purpose

Define the list picker surface used when assigning or moving a task to a list, including group disambiguation.

## MODIFIED Requirements

### Requirement: List picker displays all lists organized by groups

The system SHALL present a full-screen list picker showing all available lists grouped by their `ReminderListGroup`, with each area's default list (Inbox bucket) shown first within its area section, followed by that area's remaining lists. Lists within each area SHALL be sorted by their `sortOrder`. Areas SHALL appear in the order Work, then Personal. There SHALL be no ungrouped section.

The picker SHALL list lists from **both** areas regardless of the currently selected area, so a task can be moved between Work and Personal without leaving the editor.

#### Scenario: User opens list picker
- **WHEN** the user taps the list row in the editor
- **THEN** the system navigates to a full-screen picker showing all lists organized by area

#### Scenario: Lists are grouped correctly
- **WHEN** the list picker is displayed
- **THEN** the Work section appears first with its Inbox bucket at the top
- **AND** the Personal section appears second with its own Inbox bucket at the top
- **AND** no ungrouped section is shown

#### Scenario: Picker shows the other area's lists
- **WHEN** the editor was opened with Work selected
- **THEN** the picker SHALL still list Personal's lists
- **AND** they SHALL be selectable

### Requirement: List picker defaults based on entry context

The system SHALL pre-select the list based on where the editor was opened from. When the editor is opened from a surface with a definite list context, that list SHALL be pre-selected. When it is opened from a time screen scoped to an area, the Inbox bucket of that area SHALL be pre-selected.

#### Scenario: Opening from a list detail view
- **WHEN** the user opens the editor from a specific list's detail view
- **THEN** the list picker defaults to that list

#### Scenario: Opening from an area-scoped time screen
- **WHEN** the user opens the editor from Today, Tomorrow, or Upcoming with Personal selected
- **THEN** the list picker defaults to Personal's Inbox bucket

#### Scenario: Opening from Home
- **WHEN** the user opens the editor from a task on Home with Work selected
- **THEN** the list picker defaults to the task's current list
- **AND** SHALL NOT silently default to Work's bucket when the task is already in another list

## ADDED Requirements

### Requirement: Tasks can be retargeted across areas

The list picker SHALL be the sanctioned surface for moving a task between areas. Selecting a list in any area SHALL set the task's `reminderList` to that list, and the task's area SHALL be derived from that list's `group`. The retarget SHALL require no schema change and SHALL NOT alter any other task property.

#### Scenario: Retarget moves a task to the other area
- **WHEN** the user selects a Personal list for a task currently in Work
- **THEN** the task's `reminderList` SHALL be set to that Personal list
- **AND** the task SHALL appear under Personal's sections on Home
- **AND** it SHALL no longer appear under Work's sections

#### Scenario: Retarget preserves task data
- **WHEN** a task with a due date, notes, priority, and subtasks is retargeted across areas
- **THEN** all those properties SHALL be unchanged
- **AND** only `reminderList` SHALL differ

#### Scenario: Retarget into a bucket is allowed
- **WHEN** the user retargets a task to the other area's Inbox bucket
- **THEN** the task SHALL appear in that area's pinned bucket section
- **AND** SHALL be considered captured, not archived

#### Scenario: Retarget updates Home without leaving the editor
- **WHEN** the user retargets a task and returns to Home
- **THEN** Home SHALL show the task under the destination area's list
- **AND** SHALL NOT show it under the source area
