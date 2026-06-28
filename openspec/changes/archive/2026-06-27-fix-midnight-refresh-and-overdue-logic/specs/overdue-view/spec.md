## MODIFIED Requirements

### Requirement: Sidebar displays Overdue filter

The sidebar SHALL display an "Overdue" smart filter at the top of the smart filters section, above "Today". The Overdue entry SHALL be conditionally visible — it SHALL appear only when there is at least one incomplete task whose due date/time has passed.

For date-only tasks, the due date is compared by day: `startOfDay(dueDate) < startOfDay(now)`.
For tasks with a time component, the exact date/time is compared: `dueDate < now`.

The Overdue entry SHALL display a count badge with the number of overdue tasks. The icon and count badge SHOULD use a red/warning tint color to convey urgency.

#### Scenario: Overdue appears when tasks are overdue
- **WHEN** the user has at least one incomplete task whose due date/time has passed
- **THEN** the sidebar SHALL display an "Overdue" entry above "Today"
- **AND** the entry SHALL show a count badge with the number of overdue tasks

#### Scenario: Overdue hides when no overdue tasks
- **WHEN** the user has no incomplete tasks whose due date/time has passed
- **THEN** the sidebar SHALL NOT display the "Overdue" entry

#### Scenario: Overdue updates reactively
- **WHEN** the user completes the last overdue task
- **THEN** the "Overdue" entry SHALL disappear from the sidebar
- **WHEN** a new task's due date/time passes (becomes overdue)
- **THEN** the "Overdue" entry SHALL appear in the sidebar

### Requirement: Overdue view shows past-due tasks

The Overdue view SHALL display all incomplete tasks where the due date/time has passed. Tasks with a time component are compared by exact time (`dueDate < now`); date-only tasks are compared by day (`startOfDay(dueDate) < startOfDay(now)`). Tasks SHALL be sorted by due date (most overdue first). Each task row SHALL include the standard actionable controls (completion toggle, swipe to Today/Tomorrow/Later, swipe to delete, quick-capture, FAB).

The Overdue view SHALL reuse the same layout as other `ReminderSegmentDetailView` segments — flat list with quick-capture row and floating add button.

#### Scenario: Overdue tasks are listed
- **WHEN** the user taps "Overdue" in the sidebar
- **THEN** all incomplete tasks whose due date/time has passed SHALL be displayed
- **AND** tasks SHALL be sorted with the most overdue first
- **AND** the quick-capture row and FAB SHALL be available

#### Scenario: Rescheduling removes from Overdue
- **WHEN** the user swipes an overdue task to "Today" or "Tomorrow"
- **THEN** the task's `dueDate` SHALL be updated to today/tomorrow
- **AND** the task SHALL disappear from Overdue and appear in the respective filter

#### Scenario: Completing removes from Overdue
- **WHEN** the user completes an overdue task
- **THEN** the task SHALL disappear from Overdue
- **AND** the task SHALL appear in the Completed view
