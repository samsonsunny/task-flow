## MODIFIED Requirements

### Requirement: Per-day inline quick capture in upcoming view

#### Scenario: Committing inline field creates task with day's date
- **WHEN** the user types text in the inline field and presses return
- **THEN** a new task is created with that text
- **AND** the task's `dueDate` is set to that day's date
- **AND** the inline field clears and remains focused for rapid entry
- **AND** the keyboard stays visible for continued input
