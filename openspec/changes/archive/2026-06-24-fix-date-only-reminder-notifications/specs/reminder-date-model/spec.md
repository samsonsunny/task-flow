## ADDED Requirements

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
