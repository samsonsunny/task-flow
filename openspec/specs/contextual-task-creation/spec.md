## ADDED Requirements

### Requirement: Context-aware + button
The floating + button SHALL create tasks with context-appropriate defaults based on the currently active tab and sidebar selection.

#### Scenario: + on Today tab
- **WHEN** user is on the Today tab and taps the + button
- **THEN** a new task is created with `dueDate = today`
- **AND** the task is assigned to the currently selected sidebar list (or Inbox list if none selected)

#### Scenario: + on Tomorrow tab
- **WHEN** user is on the Tomorrow tab and taps the + button
- **THEN** a new task is created with `dueDate = tomorrow`
- **AND** the task is assigned to the currently selected sidebar list (or Inbox list if none selected)

#### Scenario: + on Upcoming tab
- **WHEN** user is on the Upcoming tab and taps the + button
- **THEN** the task editor opens with the date picker shown
- **AND** no default date is pre-filled

#### Scenario: + with a list selected in sidebar
- **WHEN** user has selected a list in the sidebar and taps the + button on any tab
- **THEN** the task is assigned to that list
- **AND** if on a date tab, the date is also set per the tab context
- **AND** if on Upcoming tab, the date is left unset

### Requirement: Quick capture row
After tapping +, a quick capture text field SHALL appear inline at the top of the task list (similar to Reminders.app). The task SHALL be created on return/submit with the contextual defaults applied.

#### Scenario: Quick capture saves with defaults
- **WHEN** user types text in the quick capture field and presses return
- **THEN** a new task is created with that text and the contextual date/list defaults
- **AND** the quick capture field clears and remains ready for the next entry

#### Scenario: Quick capture date is visible
- **WHEN** a task is created via quick capture on the Today tab
- **THEN** the task row shows today's date (or "Today") as a visual hint

### Requirement: Editor still available for full detail
If user needs to set more than just the title (e.g., list, notes, priority), the quick capture SHALL support tapping a detail disclosure button to open the full editor.

#### Scenario: Open editor from quick capture
- **WHEN** user taps the detail disclosure button next to the quick capture field
- **THEN** the full ReminderEditorView opens with the contextual defaults pre-filled
