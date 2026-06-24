## MODIFIED Requirements

### Requirement: Notifications rescheduled on app launch
The system SHALL scan all active (not completed) tasks with future `dueDate` values and `hasTime == true` on app launch and schedule any that are missing pending notifications. Tasks without a persisted `hasTime` flag SHALL use a time-component heuristic (non-midnight time signals `hasTime == true`). Tasks that are completed or deleted SHALL be excluded from this scan.

#### Scenario: App launch reschedules orphaned notifications for active tasks only
- **WHEN** the app launches and an active (not completed) task has a future `dueDate` with `hasTime == true` and no matching pending `UNNotificationRequest`
- **THEN** the system schedules a notification for that task

#### Scenario: App launch does not reschedule for date-only tasks
- **WHEN** the app launches and an active task has a future `dueDate` at midnight (00:00) with `hasTime == false`
- **THEN** the system does NOT schedule a notification for that task

#### Scenario: App launch uses heuristic for legacy tasks
- **WHEN** the app launches and an active task has a future `dueDate` with a non-midnight time component and no persisted `hasTime` field
- **THEN** the system schedules a notification for that task

#### Scenario: App launch does not re-schedule for completed tasks
- **WHEN** the app launches and a completed task has a future `dueDate`
- **THEN** the system does NOT schedule a notification for that completed task

#### Scenario: App launch does not re-schedule for deleted tasks
- **WHEN** the app launches and a deleted task still exists in the persistent store (e.g., due to crash before save)
- **THEN** the system does NOT schedule a notification for that deleted task

#### Scenario: App launch does not duplicate existing notifications
- **WHEN** the app launches and a task already has a pending `UNNotificationRequest` matching its `taskId`
- **THEN** the system does NOT schedule a duplicate notification
