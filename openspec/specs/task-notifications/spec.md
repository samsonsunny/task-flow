## ADDED Requirements

### Requirement: System schedules local notification on save-with-time
The system SHALL schedule a local `UNNotificationRequest` when a task is saved with `hasTime == true` and `dueDate` is in the future.

#### Scenario: Task saved with future time schedules notification
- **WHEN** the user saves a task with time set and the `dueDate` is in the future
- **THEN** the system schedules a local notification to fire at the task's `dueDate`

#### Scenario: Task saved with past time skips scheduling
- **WHEN** the user saves a task with time set but the `dueDate` is in the past
- **THEN** the system does NOT schedule any notification

#### Scenario: Task saved without time skips scheduling
- **WHEN** the user saves a task without setting a time (`hasTime == false`)
- **THEN** the system does NOT schedule any notification

### Requirement: Notification content matches task title
The system SHALL display the task's title as the notification body, with the default system alert sound.

#### Scenario: Notification displays task title
- **WHEN** a scheduled notification fires
- **THEN** the notification alert displays the task title and plays the default sound

### Requirement: Notification cancelled on task completion
The system SHALL cancel any pending notification when the task is marked complete.

#### Scenario: Completing task cancels notification
- **WHEN** the user marks a task as completed
- **THEN** any pending notification for that task is cancelled

### Requirement: Notification cancelled on task deletion
The system SHALL cancel any pending notification when the task is deleted.

#### Scenario: Deleting task cancels notification
- **WHEN** the user deletes a task
- **THEN** any pending notification for that task is cancelled

### Requirement: Notification rescheduled on time edit
The system SHALL cancel the existing notification and schedule a new one when a task's time is edited.

#### Scenario: Editing task time reschedules notification
- **WHEN** the user edits a task's time and saves
- **THEN** the old pending notification is cancelled and a new one is scheduled at the new time

#### Scenario: Clearing time cancels notification
- **WHEN** the user clears the time from a task (sets `hasTime == false`) and saves
- **THEN** any pending notification for that task is cancelled

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

### Requirement: Permission requested on first save-with-time
The system SHALL request notification authorization from the user on the first save of a task with a time set.

#### Scenario: Permission requested after save
- **WHEN** the user saves a task with a time set for the first time
- **THEN** the system requests notification authorization from the user

#### Scenario: Permission denied skips silently
- **WHEN** the user has denied notification permission and saves a task with a time set
- **THEN** the system does NOT schedule a notification and does not alert the user about the permission state

#### Scenario: Permission already granted schedules without re-prompt
- **WHEN** the user has already granted notification permission and saves a task with a time set
- **THEN** the system schedules the notification without re-prompting

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
