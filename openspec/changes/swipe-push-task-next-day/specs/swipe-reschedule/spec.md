## ADDED Requirements

### Requirement: Right swipe reschedules task to next day
The system SHALL reschedule a task to the next calendar day when the user performs a right swipe on the task row in Today, Tomorrow, or Overdue (within Today) views. The rescheduled due date SHALL be set to the start of the next calendar day (midnight). The swipe action SHALL be a full swipe: a single right swipe immediately reschedules the task without requiring an additional tap.

#### Scenario: Swipe task in Today moves to tomorrow
- **WHEN** the user right-swipes a task in the Today view
- **THEN** the task's due date is set to tomorrow (start of next calendar day)
- **AND** the task disappears from the Today list

#### Scenario: Swipe task in Tomorrow moves to day after tomorrow
- **WHEN** the user right-swipes a task in the Tomorrow view
- **THEN** the task's due date is set to the day after tomorrow
- **AND** the task disappears from the Tomorrow list

#### Scenario: Swipe overdue task in Today moves to tomorrow
- **WHEN** the user right-swipes an overdue task in the Overdue section of the Today view
- **THEN** the task's due date is set to tomorrow (start of next calendar day)
- **AND** the task disappears from the Overdue section

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
