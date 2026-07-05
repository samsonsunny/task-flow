## MODIFIED Requirements

### Requirement: Inline quick capture in ListDetailView

#### Scenario: Committing inline field creates task for current list
- **WHEN** the user types text in the inline field and presses return
- **THEN** a new task is created with that text
- **AND** the task's `reminderList` is set to the current list
- **AND** the task has no `dueDate`
- **AND** the new task appears directly above the inline field
- **AND** the inline field clears and remains focused for rapid entry
- **AND** the keyboard stays visible for continued input

#### Scenario: Empty commit is ignored
- **WHEN** the user presses return on an empty inline field
- **THEN** no task is created
- **AND** the inline field is dismissed

### Requirement: Inline quick capture in Today/Tomorrow views

#### Scenario: Committing creates task with segment date
- **WHEN** the user types text and presses return
- **THEN** a new task is created with that text
- **AND** the task's `dueDate` is set to the segment's date
- **AND** the new task appears above the inline field (adjacent to it at the bottom of the list)
- **AND** the field clears and remains focused
- **AND** the keyboard stays visible for continued input
