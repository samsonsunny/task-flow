# quick-capture

## Purpose

Define how the floating + button creates tasks with context-aware defaults across Today, Work, Personal, board columns, and list detail.

## Requirements

### Requirement: Floating + captures in the current context

Every task surface SHALL expose the floating + button. Tapping it SHALL open the task editor pre-filled with the surface's domain/list and date defaults.

#### Scenario: + opens the editor

- **WHEN** the user taps the floating +
- **THEN** the editor SHALL open
- **AND** its list and date SHALL reflect the current surface

### Requirement: Today capture defaults to today and Work Inbox

The Today surface SHALL default new tasks to `dueDate = today` and Work Inbox. The user MAY change either in the editor; changing the list to a Personal list SHALL move the task into Personal.

#### Scenario: Capture on Today

- **WHEN** the user taps + on Today
- **THEN** the editor SHALL pre-fill due date today
- **AND** Work Inbox SHALL be the selected list

#### Scenario: User picks a Personal list

- **WHEN** the user changes the list to a Personal list before saving
- **THEN** the task SHALL belong to Personal
- **AND** it SHALL still be due today

### Requirement: Domain capture defaults to that domain's Inbox

The Work and Personal tabs SHALL default new tasks to their own Inbox with no due date. A Work capture SHALL NOT land in Personal, and a Personal capture SHALL NOT land in Work.

#### Scenario: Capture on Work

- **WHEN** the user taps + on Work
- **THEN** Work Inbox SHALL be selected
- **AND** `dueDate` SHALL be nil

#### Scenario: Capture on Personal

- **WHEN** the user taps + on Personal
- **THEN** Personal Inbox SHALL be selected
- **AND** `dueDate` SHALL be nil

### Requirement: List detail capture targets that list

In a list detail view, + SHALL default to that list with no due date.

#### Scenario: Capture inside a list

- **WHEN** the user taps + while viewing a list
- **THEN** that list SHALL be selected
- **AND** `dueDate` SHALL be nil

### Requirement: Board capture targets the column's list

In board mode, + SHALL default to the list of the column it was invoked from. Dragging a task between columns SHALL change its list while keeping it in the same domain.

#### Scenario: Capture from a board column

- **WHEN** the user taps + in a Work board column
- **THEN** that column's list SHALL be selected
- **AND** the task SHALL remain in Work

#### Scenario: Drag between columns

- **WHEN** the user drags a task from one Work column to another
- **THEN** its list SHALL update
- **AND** its domain SHALL remain Work

### Requirement: No legacy time-tab capture surfaces

Capture SHALL NOT reference Tomorrow, Upcoming, Later, a sidebar selection, or per-day Upcoming sections. Those surfaces are not part of the app's navigation.

#### Scenario: No Tomorrow or Upcoming defaults

- **WHEN** the user captures a task
- **THEN** defaults SHALL come only from Today, Work, Personal, a list, or a board column
