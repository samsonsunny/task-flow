## MODIFIED Requirements

### Requirement: List view displays nested tasks hierarchically
`ListDetailView` SHALL display tasks in a hierarchical tree. Each subtask SHALL be indented relative to its parent. Parent tasks with children SHALL show a collapse/expand control. The default state for a parent SHALL be collapsed.

#### Scenario: Subtasks indent under parent
- **WHEN** a task has subtasks
- **THEN** each subtask row SHALL be indented by `depth * 20` points from the leading edge
- **AND** subtasks SHALL appear immediately below their parent in order

#### Scenario: Collapse hides subtasks
- **WHEN** user taps the collapse control on a parent task
- **THEN** all descendant subtasks SHALL be hidden with animation
- **AND** the collapse control SHALL update to indicate collapsed state

#### Scenario: Expand shows subtasks
- **WHEN** user taps the expand control on a collapsed parent task
- **THEN** all descendant subtasks SHALL appear with animation
- **AND** the expand control SHALL update to indicate expanded state

#### Scenario: Deep nesting renders correctly
- **WHEN** a task hierarchy has depth of N levels
- **THEN** each level SHALL indent by `depth * 20` points
- **AND** the list SHALL render correctly up to any depth (no truncation)

#### Scenario: Subtasks are collapsed by default on view load
- **WHEN** the list view loads for the first time
- **THEN** all parent tasks with subtasks SHALL have their subtask trees collapsed
- **AND** the user SHALL see only the parent task rows (no subtasks visible)
- **AND** the collapse control SHALL indicate collapsed state for each parent
