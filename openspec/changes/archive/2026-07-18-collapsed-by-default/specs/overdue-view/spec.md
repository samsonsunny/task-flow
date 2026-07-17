## ADDED Requirements

### Requirement: Overdue section in Today view defaults to collapsed
The inline overdue section in the Today segment view SHALL default to collapsed (hidden task rows). The overdue header with task count SHALL always be visible. Tapping the header SHALL expand to show overdue task rows.

#### Scenario: Overdue section hidden on view load
- **WHEN** the Today view loads and there are overdue tasks
- **THEN** the overdue header SHALL display the count of overdue tasks
- **AND** the overdue task rows SHALL NOT be visible

#### Scenario: User expands overdue section
- **WHEN** user taps the overdue section header
- **THEN** the overdue task rows SHALL appear with animation
- **AND** the chevron SHALL rotate to indicate expanded state

#### Scenario: User collapses overdue section
- **WHEN** user taps the overdue section header while expanded
- **THEN** the overdue task rows SHALL be hidden with animation
- **AND** the chevron SHALL rotate to indicate collapsed state
