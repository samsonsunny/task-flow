## ADDED Requirements

### Requirement: Subtask rows expose a context menu
Subtask rows in the task editor SHALL expose a context menu on long-press containing: Move to List ▸, a "Deadline" submenu with the due date actions, Move Up, Move Down, and Delete.

#### Scenario: Subtask context menu contents
- **WHEN** the user long-presses a subtask row in the editor
- **THEN** a context menu SHALL appear
- **AND** it SHALL contain "Move to List ▸"
- **AND** it SHALL contain the same due date actions as task rows in a "Deadline" submenu (None, a divider, then Today, Tomorrow, This Weekend, Next Week, Custom…)
- **AND** it SHALL contain "Move Up" and "Move Down" when the subtask has siblings
- **AND** it SHALL contain "Delete"

### Requirement: Move to List promotes a subtask
Tapping "Move to List" on a subtask SHALL remove it from its parent (set `parentTask = nil`), move it to the chosen list, and assign it a sort order in that list. Choosing the parent task's own list SHALL promote the subtask to a root task within that same list.

#### Scenario: Move subtask to another list
- **WHEN** the user moves a subtask to a different list via "Move to List"
- **THEN** the subtask SHALL become a root task in the destination list
- **AND** its `parentTask` SHALL be nil
- **AND** the subtask SHALL no longer appear under its former parent

#### Scenario: Move subtask to its own list promotes in place
- **WHEN** the user moves a subtask to the list its parent already belongs to
- **THEN** the subtask SHALL become a root task in that list
- **AND** it SHALL no longer appear as a subtask of the parent

### Requirement: Subtask due date actions behave like task rows
The due date actions on subtask rows SHALL behave like task rows: a "Deadline" submenu with None, a divider, then Today, Tomorrow, This Weekend, Next Week, Custom…; with the same active-item checkmark (None ticked when undated, the matching preset ticked when it matches the due date, Custom… ticked otherwise) and the same calendar-day icons on the preset rows.

#### Scenario: Clearing a subtask due date
- **WHEN** the user taps "None" for a subtask that has a due date
- **THEN** the subtask's dueDate SHALL be nil
- **AND** the subtask's scheduled notification SHALL be cancelled

#### Scenario: Custom schedule sheet for a subtask
- **WHEN** the user taps "Custom…" on a subtask row
- **THEN** the schedule sheet SHALL open with the picker auto-focused per the task due-date rule (date when no date, time when a date exists)
- **AND** committing SHALL update the subtask's dueDate

### Requirement: Move Up and Move Down reorder siblings
"Move Up" and "Move Down" SHALL swap the subtask's position with the adjacent sibling. "Move Up" on the first sibling or "Move Down" on the last sibling SHALL have no effect.

#### Scenario: Move Up reorders
- **WHEN** a parent has subtasks in order [X, Y, Z]
- **AND** the user taps "Move Up" on Y
- **THEN** the sibling order SHALL become [Y, X, Z]
- **AND** the order SHALL persist

#### Scenario: Move Down reorders
- **WHEN** a parent has subtasks in order [X, Y, Z]
- **AND** the user taps "Move Down" on X
- **THEN** the sibling order SHALL become [Y, X, Z]

#### Scenario: Boundary move has no effect
- **WHEN** the user taps "Move Up" on the first sibling
- **THEN** the sibling order SHALL be unchanged

#### Scenario: Actions hidden for a single sibling
- **WHEN** a parent has exactly one subtask
- **THEN** "Move Up" and "Move Down" SHALL NOT appear in the subtask's context menu

### Requirement: Delete available in subtask context menu
The subtask context menu SHALL include a Delete action that deletes the subtask, matching the existing swipe-to-delete behavior.

#### Scenario: Delete subtask from context menu
- **WHEN** the user long-presses a subtask and taps "Delete"
- **THEN** the subtask SHALL be deleted from SwiftData
- **AND** its descendant subtasks SHALL be deleted with it

### Requirement: Subtask rows display assigned date and time
Subtask rows in the editor SHALL display their assigned due date, and the time when a time is set, in the row's metadata line.

#### Scenario: Subtask with date and time shows both
- **WHEN** a subtask has a due date of Friday with time 3:00 PM
- **THEN** the subtask row's metadata line SHALL show the time and the date

#### Scenario: Subtask without a date shows neither
- **WHEN** a subtask has no due date
- **THEN** the subtask row SHALL NOT show a date or time in its metadata line
