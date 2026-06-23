## ADDED Requirements

### Requirement: Inline quick capture in ListDetailView

The system SHALL provide inline quick capture in ListDetailView when the user taps the floating `+` button. The inline text field SHALL appear at the top of the task list. Committing the field SHALL create a task assigned to the current list with no date.

#### Scenario: Tapping + reveals inline field
- **WHEN** the user is viewing a list in ListDetailView
- **AND** taps the floating `+` button
- **THEN** an inline text field appears at the top of the task list
- **AND** the text field is focused for immediate input
- **AND** the full editor sheet is NOT opened

#### Scenario: Committing inline field creates task for current list
- **WHEN** the user types text in the inline field and presses return
- **THEN** a new task is created with that text
- **AND** the task's `reminderList` is set to the current list
- **AND** the task has no `dueDate`
- **AND** the inline field clears and remains focused for rapid entry

#### Scenario: Chevron opens full editor with list pre-filled
- **WHEN** the user taps the chevron button on the inline field
- **THEN** the full ReminderEditorView opens as a sheet
- **AND** the `initialListID` is set to the current list
- **AND** the inline field closes

#### Scenario: Swipe-to-cancel dismisses inline field
- **WHEN** the user swipes to cancel on the inline field
- **THEN** the inline field is dismissed
- **AND** any typed text is discarded

#### Scenario: Empty commit is ignored
- **WHEN** the user presses return on an empty inline field
- **THEN** no task is created
- **AND** the field remains visible
