## MODIFIED Requirements

### Requirement: Notifications rescheduled on app launch

The system SHALL scan all tasks with future `dueDate` values on app launch and schedule any that are missing pending notifications. Tasks that are completed or deleted SHALL be excluded from this scan.

#### Scenario: App launch reschedules orphaned notifications for active tasks only
- **WHEN** the app launches and an active (not completed) task has a future `dueDate` with no matching pending `UNNotificationRequest`
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

## ADDED Requirements

### Requirement: Deleted task deletion is persisted immediately

The system SHALL persist task deletion to the persistent store immediately when a user deletes a task, ensuring the delete survives app termination.

#### Scenario: Delete persists before app terminates
- **WHEN** the user deletes a task and the app is subsequently terminated
- **THEN** the deleted task is not present in the persistent store on next launch

### Requirement: Delivered notifications removed on task deletion or completion

The system SHALL remove both pending AND already-delivered notifications from Notification Center when a task is deleted or completed.

#### Scenario: Pending notification removed on delete
- **WHEN** the user deletes a task that has a pending (unfired) notification
- **THEN** the pending notification is removed and will not fire

#### Scenario: Delivered notification removed on delete
- **WHEN** the user deletes a task whose notification has already fired and is displayed in Notification Center
- **THEN** the delivered notification is removed from Notification Center

#### Scenario: Delivered notification removed on completion
- **WHEN** the user marks a task as completed whose notification has already fired
- **THEN** the delivered notification is removed from Notification Center
