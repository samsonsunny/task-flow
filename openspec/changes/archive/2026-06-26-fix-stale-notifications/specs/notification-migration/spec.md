## ADDED Requirements

### Requirement: Stale notification cleanup on upgrade
The system SHALL perform a one-time cleanup of all pending and delivered notifications in the system queue on the first launch after the update that introduces this migration.

#### Scenario: First launch after update clears all stale notifications
- **WHEN** the app launches for the first time after this migration is introduced
- **THEN** all pending notification requests SHALL be removed from `UNUserNotificationCenter`
- **THEN** all delivered notifications SHALL be removed from `UNUserNotificationCenter`

#### Scenario: Migration runs before rescheduling
- **WHEN** the migration runs on first launch
- **THEN** the cleanup SHALL complete before any new notifications are scheduled
- **THEN** valid notifications SHALL be re-scheduled according to existing scheduling rules afterward

### Requirement: Migration runs exactly once
The system SHALL ensure the migration runs only on the first launch after update and never again on subsequent launches.

#### Scenario: Flag prevents re-execution
- **WHEN** the app launches a second time after migration completion
- **THEN** the cleanup SHALL NOT run again
- **THEN** the existing `reschedulePendingOnLaunch` gap-fill logic SHALL execute normally

#### Scenario: Reinstall resets migration
- **WHEN** a user reinstalls the app
- **THEN** the migration SHALL run on the first launch after reinstall (since UserDefaults are cleared on uninstall)

### Requirement: Valid notifications are preserved
After the cleanup, the system SHALL re-schedule all notifications that pass the current validity criteria.

#### Scenario: Active future-dated task with time gets re-scheduled
- **WHEN** a task has a future `dueDate`, `safeHasTime == true`, and `isCompleted == false`
- **THEN** a notification SHALL be scheduled for that task after migration completes

#### Scenario: Completed task notification is not re-scheduled
- **WHEN** a task has `isCompleted == true` with a future `dueDate` and `safeHasTime == true`
- **THEN** no notification SHALL be scheduled for that task after migration

#### Scenario: Date-only task notification is not re-scheduled
- **WHEN** a task has a future `dueDate` and `safeHasTime == false`
- **THEN** no notification SHALL be scheduled for that task after migration

#### Scenario: Past-due task notification is not re-scheduled
- **WHEN** a task has a past `dueDate`, `safeHasTime == true`, and `isCompleted == false`
- **THEN** no notification SHALL be scheduled for that task after migration

#### Scenario: Daily morning reminder is re-scheduled if enabled
- **WHEN** the daily morning reminder setting is enabled before migration
- **THEN** the daily morning reminder SHALL be re-scheduled after migration completes
