## Purpose

Define how the Overdue segment surfaces and orders tasks whose due dates are in the past.

## MODIFIED Requirements

### Requirement: Sidebar displays Overdue filter

The app SHALL surface overdue work in two places: a summary row on Home, and the Overdue section at the top of the pushed Today screen. There SHALL be no sidebar and no smart-filter list. Both surfaces SHALL be scoped to the selected area, and the Home summary row SHALL be visible only when the selected area has at least one incomplete task whose due date/time has passed.

For date-only tasks, the due date is compared by day: `startOfDay(dueDate) < startOfDay(now)`.
For tasks with a time component, the exact date/time is compared: `dueDate < now`.

The Home summary row SHALL display a count badge with the number of overdue tasks in the selected area, tinted to convey urgency. Tapping it SHALL push the Today screen. The count badge on the app icon SHALL remain global and is specified separately in `task-count-badge`.

#### Scenario: Overdue appears when tasks are overdue
- **WHEN** the user has at least one incomplete task in the selected area whose due date/time has passed
- **THEN** Home SHALL display an "Overdue" summary row
- **AND** the row SHALL show a count badge with the number of overdue tasks in that area

#### Scenario: Overdue hides when no overdue tasks
- **WHEN** the selected area has no incomplete tasks whose due date/time has passed
- **THEN** Home SHALL NOT display the "Overdue" summary row

#### Scenario: Overdue updates reactively
- **WHEN** the user completes the last overdue task in the selected area
- **THEN** the "Overdue" summary row SHALL disappear
- **WHEN** a task's due date/time passes, the "Overdue" summary row SHALL appear

#### Scenario: Overdue count is area-scoped
- **WHEN** Work has 2 overdue tasks and Personal has 1
- **AND** Personal is selected
- **THEN** the Home summary row SHALL show a count of 1

#### Scenario: Other area's overdue work is disclosed, not hidden
- **WHEN** Work has overdue tasks and Personal is selected
- **THEN** Home SHALL NOT count Work's tasks in the row
- **AND** the pushed time screens SHALL disclose Work's overdue count through the cross-area nudge

#### Scenario: Tapping the row pushes Today
- **WHEN** the user taps the Overdue summary row on Home
- **THEN** the Today screen SHALL be pushed
- **AND** it SHALL be scoped to the selected area

### Requirement: Overdue view shows past-due tasks

The Today screen's Overdue section SHALL display all incomplete tasks in the selected area where the due date/time has passed. Tasks with a time component are compared by exact time (`dueDate < now`); date-only tasks are compared by day (`startOfDay(dueDate) < startOfDay(now)`). Tasks SHALL be sorted by due date (most overdue first). Each task row SHALL include the standard actionable controls (completion toggle, swipe to Today/Tomorrow/Later, swipe to delete) and the screen SHALL render the capture bar.

Tasks belonging to the non-selected area SHALL NOT be listed here; they SHALL be disclosed through the cross-area nudge row.

#### Scenario: Overdue tasks are listed
- **WHEN** the user is on the Today screen with Work selected
- **THEN** all incomplete Work tasks whose due date/time has passed SHALL be displayed
- **AND** tasks SHALL be sorted with the most overdue first
- **AND** the capture bar SHALL be available

#### Scenario: Other area's tasks are not listed
- **WHEN** Personal has an overdue task and Work is selected
- **THEN** that Personal task SHALL NOT appear in the list
- **AND** a cross-area nudge SHALL report it

#### Scenario: Rescheduling removes from Overdue
- **WHEN** the user swipes an overdue task to "Today" or "Tomorrow"
- **THEN** the task's `dueDate` SHALL be updated to today/tomorrow
- **AND** the task SHALL disappear from Overdue

#### Scenario: Completing removes from Overdue
- **WHEN** the user completes an overdue task
- **THEN** the task SHALL disappear from Overdue
- **AND** the task SHALL appear in the Completed view
