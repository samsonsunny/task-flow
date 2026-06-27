## ADDED Requirements

### Requirement: Entry point is Settings

The `CompletedView` SHALL be reachable via a "Recently Completed" NavigationLink in the Settings view. It SHALL NOT be reachable from a sidebar or tab bar.

#### Scenario: Completed appears in Settings
- **WHEN** the user opens Settings
- **THEN** a "Recently Completed" NavigationLink SHALL be visible in the "Recently Completed" section of the Settings form
- **WHEN** the user taps the link
- **THEN** the `CompletedView` SHALL be pushed onto the navigation stack with a navigation title of "Completed"

### Requirement: Timeline visual rendering

The `CompletedView` SHALL display completed tasks as a visual timeline. Tasks SHALL be grouped by completion date into sections titled "Today", "Yesterday", "This Week", and "Earlier". Within each section, tasks SHALL be ordered by completion time descending.

Each timeline row SHALL display:
- A vertical line connecting all items in the group on the leading edge
- A filled dot at each task's position on the timeline line
- The task completion time formatted as a short time string (e.g., "10:30 AM")
- The task title with strikethrough and muted styling

#### Scenario: Today section shows timeline
- **WHEN** the user views completed tasks from today
- **THEN** each task SHALL show its completion time (e.g., "10:30 AM")
- **AND** a vertical line SHALL connect all tasks in the section
- **AND** each task SHALL have a filled dot at its position on the line

#### Scenario: Section headers are day names
- **WHEN** the user views completed tasks
- **THEN** tasks completed today SHALL appear under "Today"
- **AND** tasks completed yesterday SHALL appear under "Yesterday"
- **AND** tasks completed within the last 7 days but not today or yesterday SHALL appear under "This Week"
- **AND** tasks completed within the last 30 days but not within the last 7 days SHALL appear under "Earlier"

#### Scenario: Completed view is empty
- **WHEN** the user navigates to Completed
- **AND** there are no tasks completed within the last 30 days
- **THEN** the view SHALL display an appropriate empty state message

## MODIFIED Requirements

### Requirement: Completed view shows recently completed tasks

The `CompletedView` SHALL display tasks where `isCompleted == true` and `completionDate` falls within the last 30 days. Tasks SHALL be grouped into sections by completion date: "Today", "Yesterday", "This Week", "Earlier". Within each section, tasks SHALL be displayed as a visual timeline sorted by completion time descending.

Each task row SHALL display:
- The task title with a strikethrough and muted/dimmed styling
- The task's completion time (if completed today) or date context
- A filled checkmark circle indicating completion state
- A visual timeline line and dot connecting the row to its section

#### Scenario: Completed tasks are listed with sections
- **WHEN** the user navigates to Completed
- **THEN** tasks completed today SHALL appear under a "Today" section
- **AND** tasks completed yesterday SHALL appear under a "Yesterday" section
- **AND** tasks completed within the last 7 days but not today or yesterday SHALL appear under a "This Week" section
- **AND** tasks completed within the last 30 days but not within the last 7 days SHALL appear under an "Earlier" section

#### Scenario: Completed timeline shows time labels
- **WHEN** the user views completed tasks from today or yesterday
- **THEN** each task SHALL display its completion time

#### Scenario: Completed view is empty
- **WHEN** the user navigates to Completed
- **AND** there are no tasks completed within the last 30 days
- **THEN** the view SHALL display an appropriate empty state message

### Requirement: Swipe to un-complete

Each task row in the `CompletedView` SHALL support a tap on the checkmark circle to un-complete the task. Un-completing SHALL set `isCompleted = false` and clear `completionDate`. The task SHALL then reappear in its appropriate smart filter (Today, Tomorrow, Upcoming, or Later) based on its `dueDate`. Swipe-to-delete SHALL also be supported.

The view SHALL NOT include quick-capture, FAB, swipe-to-schedule, or swipe-to-move actions.

#### Scenario: Tap un-completes a task
- **WHEN** the user taps the checkmark circle on a completed task row
- **THEN** the task's `isCompleted` SHALL be set to `false`
- **AND** the task's `completionDate` SHALL be cleared
- **AND** the task SHALL disappear from the Completed view
- **AND** the task SHALL reappear in its appropriate smart filter

#### Scenario: Task returns to correct segment
- **WHEN** a task with `dueDate` set to today is un-completed
- **THEN** it SHALL appear in the Today view
- **WHEN** a task with no `dueDate` is un-completed
- **THEN** it SHALL appear in the Later view

## REMOVED Requirements

### Requirement: Sidebar contains Completed smart filter

**Reason**: Entry point changed from sidebar to Settings NavigationLink
**Migration**: Remove sidebar entry; add Settings NavigationLink instead

### Requirement: Task shows destination context

**Reason**: Align with Apple's Reminders approach — completed view shows completion information, not reappear destinations
**Migration**: Remove the destination label ("Will reappear in...") from completed task rows. The task row shows completion time instead.
