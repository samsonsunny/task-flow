## ADDED Requirements

### Requirement: Task row displays the full title without truncation
The system SHALL display the full task title in `TaskRowView`, removing the existing `.lineLimit(2)` constraint. The title SHALL have no line limit — the full text is visible without truncation. The title SHALL use 17pt regular weight with the same color, opacity, and line-spacing treatment as the current implementation.

#### Scenario: Short title displays on one line
- **WHEN** a task has a 1-line title
- **THEN** the title renders on a single line with no truncation

#### Scenario: Long title wraps across multiple lines
- **WHEN** a task has a title that requires many lines to display
- **THEN** the title wraps naturally with no artificial truncation

### Requirement: Task row shows notes when present
The system SHALL display the task's notes below the title in `TaskRowView` when the notes field is non-empty. Notes SHALL use 14pt regular weight with `textSecondary` color. The notes view SHALL NOT be rendered when the notes field is empty.

#### Scenario: Notes appear below title
- **WHEN** a task has non-empty notes
- **THEN** the notes text appears below the title, visually distinct at 14pt `textSecondary`

#### Scenario: Empty notes hide the notes row
- **WHEN** a task has empty notes
- **THEN** no notes row is rendered — no empty space is reserved

### Requirement: Task row shows contextual metadata line
The system SHALL display a single metadata line below the notes (or below the title when notes are absent) containing a subset of: time, date, and list name, separated by ` · `. The metadata line SHALL use 13pt regular weight with `textSecondary` color.

#### Scenario: Time appears when task has a time component
- **WHEN** a task has a `dueDate` with non-midnight hour/minute components
- **THEN** the formatted time (e.g. "3:45 PM") appears as the first element in the metadata line

#### Scenario: Date appears when task has a date and context does not convey it
- **WHEN** a task has a `dueDate` with a date component
- **AND** the viewing context is not Today, Tomorrow, or Upcoming
- **THEN** the formatted date (e.g. "Wed, Jun 23") appears in the metadata line

#### Scenario: Date omitted in Today segment
- **WHEN** a task has a due date
- **AND** the user is viewing the Today segment
- **THEN** the date is NOT shown in the metadata line

#### Scenario: Date omitted in Tomorrow segment
- **WHEN** a task has a due date
- **AND** the user is viewing the Tomorrow segment
- **THEN** the date is NOT shown in the metadata line

#### Scenario: Date omitted in Upcoming segment
- **WHEN** a task has a due date
- **AND** the user is viewing the Upcoming segment
- **THEN** the date is NOT shown in the metadata line

#### Scenario: Date shown in Overdue segment
- **WHEN** a task has a due date
- **AND** the user is viewing the Overdue segment
- **THEN** the date IS shown in the metadata line

#### Scenario: List name appears in segment views
- **WHEN** a task belongs to a named list
- **AND** the user is viewing a segment view (Today, Tomorrow, Upcoming, Later, Overdue)
- **THEN** the list name appears in the metadata line

#### Scenario: List name omitted in ListDetailView
- **WHEN** a task belongs to a named list
- **AND** the user is viewing the task in `ListDetailView`
- **THEN** the list name is NOT shown in the metadata line

#### Scenario: Metadata line empty when no data available
- **WHEN** a task has no due date, no time, and the list name is suppressed
- **THEN** no metadata line is rendered

### Requirement: Completed state styling applies to all row content
The system SHALL apply completed-state styling uniformly to the title, notes, and metadata when a task is completed. Completed styling SHALL use `textSecondary` color at 0.82 opacity with strikethrough on the title only.

#### Scenario: Completed task dims all row content
- **WHEN** a task is marked complete
- **THEN** the title, notes, and metadata line all render at `textSecondary` color with 0.82 opacity

### Requirement: Task row shows collapse/expand control for parents
When a task has subtasks, the task row SHALL display a collapse/expand control (chevron) at the leading edge, before the completion button. The chevron SHALL point down when expanded and right when collapsed.

#### Scenario: Chevron appears on parent task
- **WHEN** a task has one or more subtasks
- **THEN** a collapse/expand chevron SHALL appear before the completion circle
- **AND** the chevron SHALL point downward when the subtask list is expanded
- **AND** the chevron SHALL point rightward when the subtask list is collapsed

#### Scenario: No chevron on leaf task
- **WHEN** a task has no subtasks
- **THEN** no chevron SHALL be displayed

### Requirement: Subtask count appears in metadata
The metadata line SHALL include a subtask count for parent tasks, formatted as a count followed by a disclosure indicator.

#### Scenario: Parent row shows subtask count
- **WHEN** a task has subtasks
- **THEN** the metadata line SHALL display the number of direct subtasks (e.g., "3 ›")
- **AND** the count SHALL appear after any time/date/list elements

### Requirement: Segment views suppress nesting indicators
When a subtask appears in a segment view (Today, Upcoming, Later, Overdue), it SHALL NOT display indentation or collapse/expand controls. Subtasks SHALL appear as flat rows indistinguishable from top-level tasks.

#### Scenario: Subtask in Today appears flat
- **WHEN** a subtask with a due date appears in Today view
- **THEN** it SHALL render as a normal `TaskRowView` with no indentation
- **AND** no collapse/expand chevron SHALL be shown

### Requirement: Task row adapts indentation based on depth
When displayed in `ListDetailView`, a task row SHALL have leading indentation proportional to its depth in the task hierarchy.

#### Scenario: Depth-based indentation
- **WHEN** a task is at depth 0 (top-level)
- **THEN** indentation SHALL be 0 (default leading padding)

- **WHEN** a task is at depth 1
- **THEN** leading indentation SHALL be increased by 20 points relative to depth 0

- **WHEN** a task is at depth 2
- **THEN** leading indentation SHALL be increased by 40 points relative to depth 0
