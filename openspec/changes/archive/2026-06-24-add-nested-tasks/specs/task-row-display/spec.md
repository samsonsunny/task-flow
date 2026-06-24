## ADDED Requirements

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
