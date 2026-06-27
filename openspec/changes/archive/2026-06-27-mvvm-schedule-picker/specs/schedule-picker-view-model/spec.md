## ADDED Requirements

### Requirement: ViewModel owns date/time state
The ViewModel SHALL manage `dueDate`, `hasTime`, and `expandedPicker` state, initialized from an optional initial due date.

#### Scenario: Initialize from nil — no date
- **WHEN** the ViewModel is initialized with `initialDueDate: nil`
- **THEN** `dueDate` SHALL be nil, `hasTime` SHALL be false, `expandedPicker` SHALL be nil

#### Scenario: Initialize from date with time
- **WHEN** the ViewModel is initialized with a due date that has non-midnight time components
- **THEN** `hasTime` SHALL be true, `dueDate` SHALL match the input, `expandedPicker` SHALL be `.date`

#### Scenario: Initialize from date-only (midnight)
- **WHEN** the ViewModel is initialized with a due date at midnight
- **THEN** `hasTime` SHALL be false, `dueDate` SHALL match the input, `expandedPicker` SHALL be `.date`

### Requirement: ViewModel handles date toggle
The ViewModel SHALL toggle date on/off: enabling sets a default date and opens the date picker; disabling clears date, time, and picker.

#### Scenario: Enable date
- **WHEN** date is enabled with `dueDate` nil
- **THEN** `dueDate` SHALL be set to the current date and `expandedPicker` SHALL be `.date`

#### Scenario: Disable date
- **WHEN** date is disabled
- **THEN** `dueDate` SHALL be nil, `hasTime` SHALL be false, `expandedPicker` SHALL be nil

### Requirement: ViewModel handles time toggle
The ViewModel SHALL toggle time on/off: enabling sets hasTime and rounds the current time to the nearest 30-minute mark.

#### Scenario: Enable time rounds to nearest half hour
- **WHEN** time is enabled
- **THEN** `hasTime` SHALL be true, `dueDate` SHALL include the rounded time component, `expandedPicker` SHALL be `.time`

### Requirement: Shared `nearestRoundedHour()` utility
The system SHALL provide a public `nearestRoundedHour(from:)` function in `Utilities/DateRounding.swift` that rounds any date to the nearest 30-minute boundary.

#### Scenario: Rounding to nearest half hour
- **WHEN** called with a date at 10:14
- **THEN** the result SHALL be 10:30

#### Scenario: Rounding wraps across hours
- **WHEN** called with a date at 10:44
- **THEN** the result SHALL be 11:00
