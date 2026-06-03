## ADDED Requirements

### Requirement: Time toggle is always interactive
The time toggle in the Reminder Editor SHALL be enabled regardless of whether a date has been set. It SHALL NOT be `View.disabled(...)` based on `draft.dueDate`.

#### Scenario: Time toggle enabled without date
- **WHEN** the user opens the Reminder Editor
- **AND** no date has been set (`draft.dueDate` is nil)
- **THEN** the Time toggle SHALL be interactive (not disabled)

### Requirement: Auto-enable date when time is set
When the user enables the time toggle and no date is currently set, the system SHALL automatically set the date to today.

#### Scenario: Enable time without date sets today
- **WHEN** the user taps the Time toggle to enable it
- **AND** `draft.dueDate` is nil
- **THEN** `draft.dueDate` SHALL be set to `Calendar.current.startOfDay(for: Date())`

#### Scenario: Enable time with existing date does not override
- **WHEN** the user taps the Time toggle to enable it
- **AND** `draft.dueDate` is already set to a future date
- **THEN** `draft.dueDate` SHALL remain unchanged

### Requirement: Time picker expand is gated on hasTime only
The time picker SHALL expand/collapse based solely on `draft.hasTime`, not on `draft.dueDate`. The time row press highlight SHALL also be gated on `draft.hasTime` only.

#### Scenario: Expand time picker without date
- **WHEN** the user taps the time row
- **AND** `draft.hasTime` is true
- **AND** `draft.dueDate` is nil
- **THEN** the time picker SHALL expand
- **AND** the row SHALL show the press highlight on touch-down

### Requirement: Disabling time does not clear date
When the user toggles time off, the date SHALL NOT be cleared.

#### Scenario: Toggle time off retains date
- **WHEN** the user toggles the Time switch to off
- **THEN** `draft.dueDate` SHALL remain unchanged
