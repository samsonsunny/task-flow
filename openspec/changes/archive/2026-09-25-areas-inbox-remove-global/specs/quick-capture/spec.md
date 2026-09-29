## MODIFIED Requirements

### Requirement: Context-aware + button

The floating + button SHALL create tasks with context-appropriate defaults based on the currently active tab and sidebar selection. When no explicit list is selected, the task SHALL be assigned to the first group's Inbox bucket (the default capture target), resolved by pointer. When a specific list is selected, the task SHALL be assigned to that list.

#### Scenario: + on Today tab

- **WHEN** user is on the Today tab and taps the + button
- **THEN** a new task is created with `dueDate = today`
- **AND** the task is assigned to the currently selected sidebar list, or to the first group's Inbox bucket if none is selected

#### Scenario: + on Tomorrow tab

- **WHEN** user is on the Tomorrow tab and taps the + button
- **THEN** a new task is created with `dueDate = tomorrow`
- **AND** the task is assigned to the currently selected sidebar list, or to the first group's Inbox bucket if none is selected

#### Scenario: + on Upcoming tab

- **WHEN** user is on the Upcoming tab and taps the + button
- **THEN** the task editor opens with the date picker shown
- **AND** no default date is pre-filled

#### Scenario: + with a list selected in sidebar

- **WHEN** user has selected a list in the sidebar and taps the + button on any tab
- **THEN** the task is assigned to that list
- **AND** if on a date tab, the date is also set per the tab context
- **AND** if on Upcoming tab, the date is left unset

## ADDED Requirements

### Requirement: Overview capture targets the first group's bucket

When capturing on the Lists overview (sidebar column), the capture bar's default target SHALL be the first group's Inbox bucket, resolved by pointer, with no `dueDate`. If the store has no groups yet, the resolver SHALL create the default Work/Personal areas and target Work's bucket.

#### Scenario: Capture on overview creates undated bucket task

- **WHEN** the user types a task title on the Lists overview bar and submits
- **THEN** a new `TaskItem` is created with `reminderList` set to the first group's Inbox bucket
- **AND** `dueDate` is `nil`

#### Scenario: Overview capture in an empty store seeds areas first

- **WHEN** the user captures on the overview and no groups exist
- **THEN** the resolver SHALL create the default Work/Personal areas with buckets
- **AND** the captured task SHALL be assigned to the Work Inbox bucket

### Requirement: Capture target resolves from the selected surface

The capture bar's default target SHALL resolve from the active surface: the selected time segment's date on time segment roots, the selected list (undated) when viewing a list's tasks, **or the first group's Inbox bucket (undated) when viewing the Lists overview**.

#### Scenario: Capture on a time segment assigns the segment date

- **WHEN** the user captures a task on the Today segment
- **THEN** the task is created with `dueDate = start of today`
- **AND** the task is assigned to the first group's Inbox bucket

#### Scenario: Capture in a list assigns to that list

- **WHEN** the user captures a task while viewing a specific list's tasks
- **THEN** the task is created with no `dueDate`
- **AND** the task is assigned to the viewed list

#### Scenario: Capture inside a group's bucket assigns to that bucket

- **WHEN** the user captures a task while viewing a group's Inbox bucket
- **THEN** the task is created with no `dueDate`
- **AND** the task is assigned to that bucket