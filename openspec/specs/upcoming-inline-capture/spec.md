## ADDED Requirements

### Requirement: Per-day inline quick capture in upcoming view

The system SHALL allow the user to create a task inline within any day section or month sub-section of the Upcoming view. Tapping any existing "Add Reminder" CTA (dashed circle button, day header, empty day row, month day sub-section) SHALL activate an inline text field within that section. Committing the field SHALL create a task with that day's date. Only one inline field SHALL be active at a time across the entire view.

#### Scenario: Tapping Add Reminder activates inline field for that day
- **WHEN** the user taps the "Add Reminder" button at the bottom of a day section
- **THEN** an inline text field appears within that section
- **AND** no other inline field is visible in any other section
- **AND** the text field is focused

#### Scenario: Tapping a day header activates inline field for that day
- **WHEN** the user taps a day section header in the upcoming view
- **THEN** an inline text field appears within that section
- **AND** the field is pre-configured for that day's date

#### Scenario: Tapping an empty day row activates inline field
- **WHEN** the user taps an empty day row in the upcoming view
- **THEN** an inline text field appears for that day

#### Scenario: Tapping a month sub-section day activates inline field
- **WHEN** the user taps a day activation target within a month sub-section
- **THEN** an inline text field appears for that day within the sub-section

#### Scenario: Committing inline field creates task with day's date
- **WHEN** the user types text in the inline field and presses return
- **THEN** a new task is created with that text
- **AND** the task's `dueDate` is set to that day's date
- **AND** the inline field clears and remains focused for rapid entry
- **AND** the keyboard stays visible for continued input

#### Scenario: Chevron opens full editor with date pre-filled
- **WHEN** the user taps the chevron button on the inline field
- **THEN** the full ReminderEditorView opens as a sheet
- **AND** the `initialDate` is set to that day's date
- **AND** the inline field closes

#### Scenario: Tapping a different section's CTA moves the inline field
- **WHEN** the user has an inline field active in one day section
- **AND** taps the "Add Reminder" button in a different day section
- **THEN** the inline field closes in the original section
- **AND** opens in the newly tapped section
- **AND** any typed text in the original field is discarded

#### Scenario: Swipe-to-cancel dismisses the inline field
- **WHEN** the user swipes to cancel on the active inline field
- **THEN** the inline field is dismissed
- **AND** the "Add Reminder" button reappears
- **AND** any typed text is discarded
