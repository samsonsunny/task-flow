## ADDED Requirements

### Requirement: Dated subtasks resurface in segment views
Segment views (Today, Tomorrow, Upcoming, Overdue) SHALL include a subtask as a flat row when the subtask has its own due date that matches the segment. Subtasks without a due date SHALL NOT appear in any segment view.

#### Scenario: Dated subtask appears in Today
- **WHEN** a subtask has a due date of today
- **THEN** the subtask SHALL appear as a flat row in the Today segment
- **AND** it SHALL render without indentation or collapse controls
- **AND** it SHALL NOT be duplicated alongside its parent

#### Scenario: Dated subtask appears in Upcoming
- **WHEN** a subtask has a due date in the upcoming range
- **THEN** the subtask SHALL appear as a flat row in the Upcoming segment

#### Scenario: Undated subtask stays hidden
- **WHEN** a subtask has no due date
- **THEN** the subtask SHALL NOT appear in any segment view
- **AND** it SHALL remain visible only in its task's editor

#### Scenario: Overdue subtask appears in Overdue
- **WHEN** a subtask has a due date earlier than today
- **THEN** the subtask SHALL appear in the Overdue section of the Today segment
