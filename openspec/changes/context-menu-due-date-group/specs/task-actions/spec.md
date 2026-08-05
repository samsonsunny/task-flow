## ADDED Requirements

### Requirement: Move Up and Move Down actions for subtasks
Subtask rows in the task editor SHALL expose "Move Up" and "Move Down" context-menu actions that reorder the subtask among its siblings. The actions SHALL NOT appear when the parent has fewer than two subtasks.

#### Scenario: Move Up reorders siblings
- **WHEN** a parent has children in order [X, Y, Z]
- **AND** the user long-presses Y and taps "Move Up"
- **THEN** the children SHALL be reordered to [Y, X, Z]
- **AND** the order SHALL persist across app restarts

#### Scenario: Move Down reorders siblings
- **WHEN** a parent has children in order [X, Y, Z]
- **AND** the user long-presses X and taps "Move Down"
- **THEN** the children SHALL be reordered to [Y, X, Z]

#### Scenario: Boundary move has no effect
- **WHEN** the user taps "Move Up" on the first sibling
- **THEN** the sibling order SHALL be unchanged

#### Scenario: Actions hidden with a single sibling
- **WHEN** a parent has exactly one child
- **THEN** "Move Up" and "Move Down" SHALL NOT appear in that child's context menu
