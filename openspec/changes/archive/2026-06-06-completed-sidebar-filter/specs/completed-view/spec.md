## ADDED Requirements

### Requirement: Sidebar contains Completed smart filter

The sidebar SHALL display a "Completed" smart filter in the smart filters section, below "Later". Tapping "Completed" SHALL navigate to the `CompletedView` detail.

The sidebar SHALL NOT show a task count badge for the Completed filter.

"Completed" SHALL NOT appear as a tab in `FilterDetailView`/`SmartFilterTabbedView`.

#### Scenario: Completed appears in sidebar
- **WHEN** the user views the sidebar
- **THEN** a "Completed" navigation link SHALL be visible below "Later"
- **AND** it SHALL use a `checkmark.circle.fill` (or equivalent) icon
- **AND** it SHALL NOT display a count badge

#### Scenario: Completed is not in tab bar
- **WHEN** the user views any smart filter via the TabView
- **THEN** the tab bar SHALL NOT include a "Completed" tab

### Requirement: Completed view shows recently completed tasks

The `CompletedView` SHALL display tasks where `isCompleted == true` and `completionDate` falls within the last 30 days. Tasks SHALL be grouped into sections by completion date: "Today", "Yesterday", "This Week", "Earlier".

Each task row SHALL display:
- The task title with a strikethrough and muted/dimmed styling
- The task's due date or destination segment (e.g., "Overdue", "Today", "Later") to indicate where it will reappear upon un-complete
- A leading checkmark icon indicating completion state

#### Scenario: Completed tasks are listed with sections
- **WHEN** the user navigates to Completed
- **THEN** tasks completed today SHALL appear under a "Today" section
- **AND** tasks completed yesterday SHALL appear under a "Yesterday" section
- **AND** tasks completed within the last 7 days but not today or yesterday SHALL appear under a "This Week" section
- **AND** tasks completed within the last 30 days but not within the last 7 days SHALL appear under an "Earlier" section

#### Scenario: Completed view is empty
- **WHEN** the user navigates to Completed
- **AND** there are no tasks completed within the last 30 days
- **THEN** the view SHALL display an appropriate empty state message

#### Scenario: Task shows destination context
- **WHEN** the user views a completed task row
- **THEN** the row SHALL indicate where the task will reappear if un-completed (based on its `dueDate`)

### Requirement: Swipe to un-complete

Each task row in the `CompletedView` SHALL support a swipe gesture to un-complete the task. Un-completing SHALL set `isCompleted = false` and clear `completionDate`. The task SHALL then reappear in its appropriate smart filter (Today, Tomorrow, Upcoming, or Later) based on its `dueDate`.

The view SHALL NOT include quick-capture, FAB, swipe-to-schedule, or swipe-to-move actions.

#### Scenario: Swipe un-completes a task
- **WHEN** the user swipes a completed task row
- **THEN** the task's `isCompleted` SHALL be set to `false`
- **AND** the task's `completionDate` SHALL be cleared
- **AND** the task SHALL disappear from the Completed view
- **AND** the task SHALL reappear in its appropriate smart filter

#### Scenario: Task returns to correct segment
- **WHEN** a task with `dueDate` set to today is un-completed
- **THEN** it SHALL appear in the Today view
- **WHEN** a task with no `dueDate` is un-completed
- **THEN** it SHALL appear in the Later view
