## MODIFIED Requirements

### Requirement: Quick capture row
After tapping +, a quick capture text field SHALL appear inline at the top of the task list (similar to Reminders.app) for all segments EXCEPT Upcoming. For the Upcoming segment, the floating + SHALL open the full editor instead. The task SHALL be created on return/submit with the contextual defaults applied.

#### Scenario: Quick capture saves with defaults
- **WHEN** user types text in the quick capture field and presses return
- **AND** the current segment is not Upcoming
- **THEN** a new task is created with that text and the contextual date/list defaults
- **AND** the quick capture field clears and remains ready for the next entry

#### Scenario: Quick capture date is visible
- **WHEN** a task is created via quick capture on the Today tab
- **THEN** the task row shows today's date (or "Today") as a visual hint

#### Scenario: Quick capture not available in Upcoming
- **WHEN** user is on the Upcoming tab and taps the floating +
- **THEN** the full ReminderEditorView opens
- **AND** no inline quick capture field appears
