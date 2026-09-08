## ADDED Requirements

### Requirement: Capture bar presence is surface-aware

The capture bar SHALL be shown on task surfaces only — the time segment roots (Today, Tomorrow, Upcoming) in the detail column, and inside a selected list's task view. The capture bar SHALL NOT be shown on the Lists overview (the root of the sidebar column, where no single task surface exists).

#### Scenario: Capture bar on time segment roots
- **WHEN** the user is on the Today, Tomorrow, or Upcoming segment
- **THEN** the capture bar is visible at the bottom of the detail column

#### Scenario: Capture bar inside a list's tasks
- **WHEN** the user has selected a list and is viewing its tasks
- **THEN** the capture bar is visible at the bottom of the detail column
- **AND** captured tasks are assigned to the selected list

#### Scenario: No capture bar on the Lists overview
- **WHEN** the user is viewing the Lists overview (list of lists, groups, and Inbox)
- **THEN** the capture bar is NOT visible
- **AND** no task-capture surface is presented alongside the list row grid

### Requirement: Capture target resolves from the selected surface

The capture bar's default target SHALL resolve from the active surface: the selected time segment (date) on time segment roots, or the selected list (undated) when viewing a list's tasks.

#### Scenario: Capture on a time segment assigns the segment date
- **WHEN** the user captures a task on the Today segment
- **THEN** the task is created with `dueDate = start of today`
- **AND** the task is assigned to the default Inbox list

#### Scenario: Capture in a list assigns to that list
- **WHEN** the user captures a task while viewing a specific list's tasks
- **THEN** the task is created with no `dueDate`
- **AND** the task is assigned to the viewed list