# overdue-view

## Purpose

Define how overdue tasks surface inside the cross-domain Today tab.

## Requirements

### Requirement: Today shows an Overdue section

The Today tab SHALL show a collapsible "Overdue" section above today's tasks when at least one incomplete task from Work or Personal is past due. There SHALL NOT be a sidebar smart filter or a separate Overdue tab.

For date-only tasks, overdue means `startOfDay(dueDate) < startOfDay(now)`. For tasks with a time, overdue means `dueDate < now`.

#### Scenario: Overdue section appears

- **WHEN** at least one incomplete task is overdue
- **THEN** Today SHALL show an Overdue section above the Today section
- **AND** the header SHALL display the overdue count

#### Scenario: Overdue section hides

- **WHEN** no incomplete tasks are overdue
- **THEN** Today SHALL NOT show an Overdue section

#### Scenario: Overdue updates reactively

- **WHEN** the user completes the last overdue task
- **THEN** the Overdue section SHALL disappear
- **WHEN** a task becomes overdue
- **THEN** the Overdue section SHALL appear

### Requirement: Overdue ordering and controls

Overdue tasks SHALL be sorted most overdue first. Each row SHALL use the standard task row with completion toggle, edit, reschedule, and delete actions. Rescheduling SHALL remove the task from Overdue.

#### Scenario: Most overdue first

- **WHEN** multiple tasks are overdue
- **THEN** the earliest due date SHALL appear first

#### Scenario: Rescheduling removes from Overdue

- **WHEN** the user reschedules an overdue task to today or tomorrow
- **THEN** it SHALL leave the Overdue section
- **AND** it SHALL appear under the appropriate date

#### Scenario: Completing removes from Overdue

- **WHEN** the user completes an overdue task
- **THEN** it SHALL leave Today
- **AND** it SHALL appear in Recently Completed

### Requirement: Overdue section is collapsible

The Overdue header SHALL remain visible while collapsed. Tapping it SHALL toggle the overdue rows, and the chevron SHALL reflect the state.

#### Scenario: Collapse and expand

- **WHEN** the user taps the Overdue header
- **THEN** its task rows SHALL toggle visibility
- **AND** the chevron SHALL update
