## ADDED Requirements

### Requirement: Left swipe postpones task to next day
The system SHALL postpone a task to the next calendar day when the user performs a left swipe on the task row in Today, Tomorrow, or Overdue (within Today) views. The rescheduled due date SHALL be set to start of the next calendar day relative to the task's current due date (or today if the task has no due date). The swipe action SHALL be a full swipe: a single left swipe immediately reschedules the task without requiring an additional tap.

#### Scenario: Swipe task in Today moves to tomorrow
- **WHEN** the user left-swipes a task in the Today view
- **THEN** the task's due date is set to tomorrow (start of next calendar day)
- **AND** the task disappears from the Today list

#### Scenario: Swipe task in Tomorrow moves to day after tomorrow
- **WHEN** the user left-swipes a task in the Tomorrow view
- **THEN** the task's due date is set to the day after tomorrow
- **AND** the task disappears from the Tomorrow list

#### Scenario: Swipe overdue task in Today moves to tomorrow
- **WHEN** the user left-swipes an overdue task in the Overdue section of the Today view
- **THEN** the task's due date is set to tomorrow (start of next calendar day)
- **AND** the task disappears from the Overdue section

### Requirement: Right swipe deletes task
The system SHALL show the existing destructive delete swipe action on the trailing (right) edge for all task rows, including those in Today and Tomorrow views.

#### Scenario: Right swipe deletes task
- **WHEN** the user right-swipes a task row
- **THEN** the delete swipe action is shown

### Requirement: Reschedule triggers light haptic feedback
The system SHALL trigger a light haptic feedback (`UIImpactFeedbackGenerator(style: .light)`) when a task is successfully rescheduled via swipe.

#### Scenario: Haptic fires on swipe reschedule
- **WHEN** the swipe reschedule action completes
- **THEN** a light haptic feedback is triggered

### Requirement: Swipe reschedule preserves notification scheduling
If the rescheduled task had a notification scheduled, the system SHALL cancel the existing notification and reschedule it for the new due date according to the task's notification settings.

#### Scenario: Notification rescheduled on swipe
- **WHEN** a task with a scheduled notification is rescheduled via swipe
- **THEN** the old notification is cancelled
- **AND** a new notification is scheduled for the new due date

### Requirement: Swipe reschedule tracks deferral count
The system SHALL increment the task's `deferCount` each time it is rescheduled via swipe. When `deferCount >= 2`, the task row metadata SHALL display the deferral count (e.g., "3x deferred") as a subtle indicator.

#### Scenario: First deferral not shown
- **WHEN** a task is rescheduled via swipe for the first time
- **THEN** `deferCount` is set to 1
- **AND** no deferral indicator is shown in the task row

#### Scenario: Repeated deferrals shown
- **WHEN** a task with `deferCount >= 2` is rendered in a task row
- **THEN** the metadata line includes "Nx deferred" (where N is the defer count)
