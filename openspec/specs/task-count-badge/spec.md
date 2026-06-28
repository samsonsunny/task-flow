## ADDED Requirements

### Requirement: Badge shows overdue + today task count
The system SHALL display a badge on the app icon equal to the number of uncompleted tasks that are overdue or due today.

#### Scenario: Badge displays on app icon
- **WHEN** the app has uncompleted tasks that are overdue or due today
- **THEN** the app icon shows a badge with the count of those tasks
- **AND** the badge persists across app restarts

#### Scenario: Badge updates after completing a task
- **WHEN** the user completes a task that was overdue or due today
- **THEN** the badge decrements by one after the 0.6s exit animation delay

#### Scenario: Badge updates when a task becomes overdue
- **WHEN** a task's due date passes (now > due date end of day)
- **THEN** the badge increments to include the newly overdue task

#### Scenario: Badge reaches zero
- **WHEN** all overdue and today-due tasks are completed or rescheduled
- **THEN** the badge is removed (shows no number)

#### Scenario: Badge does not clear on app open
- **WHEN** the user opens the app
- **THEN** the badge remains visible at the current task count
- **AND** only the notification tray is cleared (per `clear-notifications-on-open`)

### Requirement: Notifications carry the badge number
The system SHALL set `content.badge` on every scheduled notification so that the badge appears even if the app is not running when the notification fires.

#### Scenario: Badge appears from notification
- **WHEN** a notification fires while the app is not running
- **THEN** the badge displays a number (the value last set on the notification content)

### Requirement: Badge authorization
The system SHALL request `.badge` authorization alongside `.alert` and `.sound`.

#### Scenario: Authorization includes badge
- **WHEN** the user grants notification permission
- **THEN** the app is authorized to set badge numbers
