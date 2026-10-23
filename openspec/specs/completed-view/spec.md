# completed-view

## Purpose

Define the Recently Completed view, reached from More, including completion-date grouping and un-complete behavior.

## Requirements

### Requirement: Completed lives under More

The Recently Completed view SHALL be reached from More → Recently Completed. It SHALL NOT appear as a root tab and SHALL NOT be a sidebar smart filter.

#### Scenario: Open from More

- **WHEN** the user taps Recently Completed in More
- **THEN** `CompletedView` SHALL be pushed within More's navigation stack

#### Scenario: Not in the tab bar

- **WHEN** the user views the root tab bar
- **THEN** there SHALL be no Completed tab

### Requirement: Completed view shows the last 30 days

`CompletedView` SHALL display tasks where `isCompleted == true` and `completionDate` is within the last 30 days, grouped by completion date: "Today", "Yesterday", "This Week", "Earlier".

Each row SHALL show the task title with completion styling and the task's list name as context.

#### Scenario: Completed tasks are grouped

- **WHEN** the user opens Recently Completed
- **THEN** tasks completed today SHALL appear under Today
- **AND** tasks completed yesterday SHALL appear under Yesterday
- **AND** tasks completed in the last 7 days SHALL appear under This Week
- **AND** older tasks within 30 days SHALL appear under Earlier

#### Scenario: Empty state

- **WHEN** no tasks were completed in the last 30 days
- **THEN** the view SHALL show an empty state

#### Scenario: Row shows list context

- **WHEN** a completed task is shown
- **THEN** its row SHALL include the list it belongs to

### Requirement: Swipe to un-complete

Swiping a completed row SHALL set `isCompleted = false` and clear `completionDate`. The task SHALL return to its owning list and to Today if it is due today or overdue. Un-completing SHALL reschedule notifications when appropriate.

Un-completed tasks with no due date SHALL remain in their Work/Personal list and SHALL NOT appear in a separate Later view.

#### Scenario: Un-complete a task due today

- **WHEN** the user swipes a task that was due today
- **THEN** it SHALL disappear from Recently Completed
- **AND** it SHALL appear in Today

#### Scenario: Un-complete an undated task

- **WHEN** the user un-completes a task with no due date
- **THEN** it SHALL remain in its Work or Personal list
- **AND** it SHALL NOT appear in Today until given a due date

#### Scenario: No capture or move actions

- **WHEN** the user views Recently Completed
- **THEN** there SHALL be no quick-capture, FAB, or list-move actions
