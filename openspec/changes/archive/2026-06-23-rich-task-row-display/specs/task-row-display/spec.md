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
