## Purpose

Define how the Completed view lists, filters, and presents finished tasks, including grouping by completion date and bulk clearing.

## MODIFIED Requirements

### Requirement: Sidebar contains Completed smart filter

The app SHALL provide access to `CompletedView` from Home's overflow menu in the navigation bar's trailing position. There SHALL be no sidebar and no "Completed" entry in the area switcher. Home's overflow menu SHALL NOT display a task count badge for the Completed entry.

"Completed" SHALL NOT be reachable as a top-level destination; it is a pushed screen, not a mode.

#### Scenario: Completed is reachable from Home's overflow menu
- **WHEN** the user opens Home's overflow menu
- **THEN** a "Completed" entry SHALL be visible below "Select Items"
- **AND** it SHALL use a `checkmark.circle.fill` (or equivalent) icon
- **AND** it SHALL NOT display a count badge

#### Scenario: Tapping Completed pushes the view
- **WHEN** the user taps "Completed" in Home's overflow menu
- **THEN** `CompletedView` SHALL be pushed onto the navigation stack

#### Scenario: Completed is not a mode
- **WHEN** the user views the area switcher
- **THEN** it SHALL contain exactly two area pills
- **AND** SHALL NOT contain a Completed entry

### Requirement: Completed view shows recently completed tasks

The `CompletedView` SHALL display tasks where `isCompleted == true` and `completionDate` falls within the last 30 days. Tasks SHALL be grouped into sections by completion date: "Today", "Yesterday", "This Week", "Earlier". The view SHALL NOT be scoped to the selected area; it shows completed tasks from both areas, because a completed task's area is not a mode the user is browsing.

Each task row SHALL display:
- The task title with a strikethrough and muted/dimmed styling
- The task's list name, so the user can tell which area the task belonged to
- The task's due date or destination segment (e.g., "Overdue", "Today", "Undated") to indicate where it will reappear upon un-complete
- A leading checkmark icon indicating completion state

#### Scenario: Completed tasks are listed with sections
- **WHEN** the user navigates to Completed
- **THEN** tasks completed today SHALL appear under a "Today" section
- **AND** tasks completed yesterday SHALL appear under a "Yesterday" section
- **AND** tasks completed within the last 7 days but not today or yesterday SHALL appear under a "This Week" section
- **AND** tasks completed within the last 30 days but not within the last 7 days SHALL appear under an "Earlier" section

#### Scenario: Completed view spans both areas
- **WHEN** a completed Work task and a completed Personal task exist
- **THEN** both SHALL appear in the Completed view
- **AND** each SHALL show its list name

#### Scenario: Completed view is empty
- **WHEN** the user navigates to Completed
- **AND** there are no tasks completed within the last 30 days
- **THEN** the view SHALL display an appropriate empty state message

#### Scenario: Task shows destination context
- **WHEN** the user views a completed task row
- **THEN** the row SHALL indicate where the task will reappear if un-completed (based on its `dueDate`)

### Requirement: Swipe to un-complete

Each task row in the `CompletedView` SHALL support a swipe gesture to un-complete the task. Un-completing SHALL set `isCompleted = false` and clear `completionDate`. The task SHALL then reappear on the surface matching its `dueDate`, within its own area. A task with no `dueDate` SHALL reappear on Home in its list's section, within its own area.

The view SHALL NOT include a capture bar, swipe-to-schedule, or swipe-to-move actions.

#### Scenario: Swipe un-completes a task
- **WHEN** the user swipes a completed task row
- **THEN** the task's `isCompleted` SHALL be set to `false`
- **AND** the task's `completionDate` SHALL be cleared
- **AND** the task SHALL disappear from the Completed view
- **AND** the task SHALL reappear on the surface matching its `dueDate`, within its own area

#### Scenario: Task returns to the correct surface and area
- **WHEN** a task with `dueDate` set to today is un-completed
- **THEN** it SHALL appear on the Today screen
- **WHEN** a task with no `dueDate` is un-completed
- **THEN** it SHALL appear on Home in its list's section
- **AND** in both cases it SHALL appear only under the area that owns its list
