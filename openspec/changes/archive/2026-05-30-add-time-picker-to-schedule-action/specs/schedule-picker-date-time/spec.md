## ADDED Requirements

### Requirement: Schedule sheet with date toggle and expandable picker

The schedule sheet SHALL display a date toggle row. When the date toggle is on, the selected date SHALL appear as a subtitle. Tapping the row SHALL expand/collapse a graphical date picker inline. When the date toggle is turned off, the time toggle SHALL also turn off and all date/time state SHALL be cleared.

#### Scenario: Date toggle defaults to on for tasks with dueDate
- **WHEN** the schedule sheet opens for a task that has a dueDate
- **THEN** the date toggle SHALL be on
- **AND** the subtitle SHALL show the task's existing due date

#### Scenario: Date toggle defaults to off for tasks without dueDate
- **WHEN** the schedule sheet opens for a task that has no dueDate
- **THEN** the date toggle SHALL be off
- **AND** no subtitle SHALL be displayed

#### Scenario: Date toggle turns on with current date
- **WHEN** the user turns on the date toggle
- **THEN** dueDate SHALL be set to the current date
- **AND** the date picker SHALL expand

#### Scenario: Date row tapping expands and collapses picker
- **WHEN** the date toggle is on
- **AND** the user taps the date row
- **THEN** the date picker SHALL expand inline below the row
- **WHEN** the user taps the date row again
- **THEN** the date picker SHALL collapse

#### Scenario: Date toggle turns off clears date and time
- **WHEN** the date toggle is on
- **AND** the time toggle is on
- **AND** the user turns off the date toggle
- **THEN** dueDate SHALL be set to nil
- **AND** hasTime SHALL be set to false
- **AND** all pickers SHALL collapse

### Requirement: Schedule sheet with time toggle and expandable picker

The schedule sheet SHALL display a time toggle row beneath the date row. When the time toggle is on, the selected time SHALL appear as a subtitle. Tapping the row SHALL expand/collapse a wheel time picker inline. Turning on time SHALL auto-enable the date toggle if it is off.

#### Scenario: Time toggle is off by default
- **WHEN** the schedule sheet opens
- **THEN** the time toggle SHALL be off
- **AND** no time subtitle SHALL be displayed

#### Scenario: Time toggle turns on with nearest rounded hour
- **WHEN** the user turns on the time toggle
- **THEN** hasTime SHALL be set to true
- **AND** if dueDate is nil, dueDate SHALL be set to the current date
- **AND** the time SHALL default to the nearest future 30-minute boundary
- **AND** the time picker SHALL expand

#### Scenario: Time toggle turns off preserves date
- **WHEN** the time toggle is on
- **AND** the user turns off the time toggle
- **THEN** hasTime SHALL be set to false
- **AND** dueDate SHALL remain unchanged
- **AND** the time picker SHALL collapse

#### Scenario: Time row tapping expands and collapses picker
- **WHEN** the time toggle is on
- **AND** the user taps the time row
- **THEN** the time picker SHALL expand inline below the row
- **WHEN** the user taps the time row again
- **THEN** the time picker SHALL collapse

#### Scenario: Picker mutual exclusion
- **WHEN** the date picker is expanded
- **AND** the user taps the time row to expand
- **THEN** the date picker SHALL collapse
- **AND** the time picker SHALL expand

### Requirement: Commit and discard behavior

The schedule sheet SHALL use Cancel/Done toolbar buttons. Cancel SHALL discard all toggle/picker changes and restore the task's original dueDate. Done SHALL commit the current state to the task.

#### Scenario: Done commits changes
- **WHEN** the user toggles date/time
- **AND** taps Done
- **THEN** the task's dueDate SHALL be updated to the selected date
- **AND** if hasTime is true, the time component SHALL be preserved
- **AND** if hasTime is false, the time component SHALL be stripped (start of day)

#### Scenario: Cancel discards changes
- **WHEN** the user toggles date/time
- **AND** taps Cancel
- **THEN** the task's dueDate SHALL remain unchanged

#### Scenario: Clearing date removes dueDate
- **WHEN** the date toggle is turned off
- **AND** the user taps Done
- **THEN** the task's dueDate SHALL be set to nil
