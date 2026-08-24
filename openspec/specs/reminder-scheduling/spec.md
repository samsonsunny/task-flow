# reminder-scheduling

## Purpose

Define the date/time scheduling model: how `hasTime` is persisted and inferred, and how the date/time toggles behave in the editor's schedule section and inline schedule sheet.

Consolidates (2026-08): `reminder-date-model`, `reminder-deadline-time`.

## Requirements

### Requirement: Reminder persists time toggle state
The system SHALL persist the user's time toggle state (`hasTime`) on the `TaskItem` model so that notification scheduling decisions can be made reliably across app restarts.

#### Scenario: New reminder saved with time set persists hasTime
- **WHEN** the user creates a new reminder and enables the time toggle
- **THEN** the task is saved with `hasTime == true`

#### Scenario: New reminder saved without time set persists hasTime
- **WHEN** the user creates a new reminder and does not enable the time toggle
- **THEN** the task is saved with `hasTime == false`

#### Scenario: Editing reminder with time preserves hasTime
- **WHEN** the user edits an existing reminder that has `hasTime == true`
- **THEN** the `ReminderDraft` initializes with `hasTime == true`

#### Scenario: Editing date-only reminder preserves hasTime
- **WHEN** the user edits an existing reminder that has `hasTime == false`
- **THEN** the `ReminderDraft` initializes with `hasTime == false`

### Requirement: Schedule sheet persists time toggle state
The system SHALL persist the time toggle state when scheduling a reminder via the inline schedule sheet (in `ListDetailView` and `ReminderSegmentDetailView`).

#### Scenario: Schedule sheet with time saves hasTime
- **WHEN** the user schedules a reminder via the schedule sheet with the time toggle enabled
- **THEN** the task is saved with `hasTime == true`

#### Scenario: Schedule sheet without time saves hasTime
- **WHEN** the user schedules a reminder via the schedule sheet without the time toggle enabled
- **THEN** the task is saved with `hasTime == false`

### Requirement: Existing reminders without hasTime use time heuristic
The system SHALL infer `hasTime` for legacy reminders (saved before this change) using a time-component heuristic: if the `dueDate` has a non-midnight time (hour != 0 or minute != 0), treat as `hasTime == true`; otherwise treat as `hasTime == false`.

#### Scenario: Legacy date-only reminder does not trigger notification
- **WHEN** an existing reminder saved before this change has a `dueDate` at midnight (00:00) and no `hasTime` field
- **THEN** the system does NOT schedule a notification for that reminder

#### Scenario: Legacy time-enabled reminder triggers notification
- **WHEN** an existing reminder saved before this change has a `dueDate` with a non-midnight time component and no `hasTime` field
- **THEN** the system schedules a notification for that reminder

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
