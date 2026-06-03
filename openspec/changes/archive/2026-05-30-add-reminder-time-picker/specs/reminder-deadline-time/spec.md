## ADDED Requirements

### Requirement: Date toggle with expandable inline picker

The schedule section SHALL display a date row with a toggle and a subtitle showing the selected date when the toggle is on. Tapping the row SHALL expand it inline with a date picker showing only date components. Selecting a date SHALL collapse the picker and update the subtitle. Expanding the date picker SHALL automatically collapse the time picker if it is open.

#### Scenario: Date toggle defaults to off
- **WHEN** a new reminder is created
- **AND** no default date is provided
- **THEN** the date toggle SHALL be off
- **AND** no subtitle SHALL be displayed
- **AND** the time row SHALL be disabled

#### Scenario: Date toggle turns on with default date
- **WHEN** the user turns on the date toggle
- **THEN** the dueDate SHALL be set to the current date
- **AND** the selected date SHALL appear as a subtitle on the date row

#### Scenario: Date toggle turns on from initialDate
- **WHEN** a new reminder is created
- **AND** an `initialDate` is provided by the caller (e.g., from tab context)
- **THEN** the date toggle SHALL be on
- **AND** the dueDate SHALL be set to the provided `initialDate`
- **AND** the selected date SHALL appear as a subtitle on the date row
- **AND** the time toggle SHALL remain off by default

#### Scenario: Date row tapping expands and collapses picker
- **WHEN** the date toggle is on
- **AND** the user taps the date row
- **THEN** the date picker SHALL expand inline below the row
- **WHEN** the user selects a date
- **THEN** the picker SHALL collapse
- **AND** the subtitle SHALL update to the selected date

#### Scenario: Date toggle turns off removes time
- **WHEN** the date toggle is on
- **AND** the time toggle is on
- **AND** the user turns off the date toggle
- **THEN** the dueDate SHALL be set to nil
- **AND** the time toggle SHALL be turned off automatically
- **AND** the time selection SHALL be cleared

### Requirement: Time toggle with expandable inline picker

The schedule section SHALL display a time row beneath the date row. The time toggle SHALL only be interactive when a date is set. When the time toggle is on, the selected time SHALL appear as a subtitle. Tapping the row SHALL expand it inline with a time picker. Expanding the time picker SHALL automatically collapse the date picker if it is open.

#### Scenario: Time toggle is disabled when no date is set
- **WHEN** the date toggle is off
- **THEN** the time toggle SHALL be visually disabled
- **AND** the time toggle SHALL be non-interactive

#### Scenario: Time toggle enables when date is set
- **WHEN** the user turns on the date toggle
- **THEN** the time toggle SHALL become interactive

#### Scenario: Time auto-selects nearest rounded hour
- **WHEN** the user turns on the time toggle for the first time
- **THEN** the time SHALL default to the nearest future 30-minute boundary
- **AND** the selected time SHALL appear as a subtitle on the time row

#### Scenario: Time picker expands and collapses
- **WHEN** the time toggle is on
- **AND** the user taps the time row
- **THEN** the time picker SHALL expand inline below the row
- **WHEN** the user selects a time
- **THEN** the picker SHALL collapse
- **AND** the subtitle SHALL update to the selected time

### Requirement: Time preserved on save

When a reminder with a deadline time is saved, the time component of the dueDate SHALL be preserved in persistence.

#### Scenario: Time component saved
- **WHEN** the user sets a date and time
- **AND** saves the reminder
- **THEN** the persisted dueDate SHALL include the time component
- **AND** re-opening the reminder SHALL show the same date and time

#### Scenario: Date-only reminders preserve midnight
- **WHEN** the user sets only a date without enabling time
- **AND** saves the reminder
- **THEN** the persisted dueDate SHALL be normalized to start of day (midnight)

### Requirement: Edit behavior preserves time

When editing an existing reminder, the `hasTime` state SHALL be derived from the existing `dueDate`. Reminders saved with a time SHALL re-open with time enabled; date-only reminders SHALL re-open with time disabled.

#### Scenario: Editing a reminder with time shows both toggles on
- **WHEN** the user taps an existing reminder whose `dueDate` has a non-midnight time component
- **THEN** the date toggle SHALL be on
- **AND** the time toggle SHALL be on
- **AND** the date subtitle SHALL show the stored date
- **AND** the time subtitle SHALL show the stored time

#### Scenario: Editing a date-only reminder shows date toggle on, time off
- **WHEN** the user taps an existing reminder whose `dueDate` is at midnight (00:00)
- **THEN** the date toggle SHALL be on
- **AND** the time toggle SHALL be off
