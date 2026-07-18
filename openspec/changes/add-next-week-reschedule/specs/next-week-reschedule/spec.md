## ADDED Requirements

### Requirement: Next Week context menu action

The system SHALL provide a "Next Week" option in the task context menu that moves the task's due date to the next Monday.

#### Scenario: Move Friday task to next Monday

- **WHEN** a task is due today (Friday) and the user long-presses and taps "Next Week"
- **THEN** the task's dueDate is set to the next Monday
- **AND** the task disappears from the Today view
- **AND** the task appears in the Upcoming view

#### Scenario: Move any weekday task to next Monday

- **WHEN** a task is due on any weekday (Mon–Fri) and the user taps "Next Week"
- **THEN** the task's dueDate is set to the next Monday (always forward, never today)

#### Scenario: Move overdue task to next Monday

- **WHEN** a task is overdue and the user taps "Next Week"
- **THEN** the task's dueDate is set to the next Monday

### Requirement: Hide when already due next Monday

The system SHALL hide the "Next Week" option when the task is already due on the next Monday.

#### Scenario: Task already due next Monday

- **WHEN** a task's dueDate is the next Monday
- **AND** the user long-presses the task
- **THEN** "Next Week" does not appear in the context menu

### Requirement: Cancel notification on move

The system SHALL cancel any existing notification for the task when "Next Week" is selected.

#### Scenario: Timed task loses notification

- **WHEN** a task has a timed notification scheduled
- **AND** the user taps "Next Week"
- **THEN** the existing notification is cancelled
- **AND** the task's dueDate is set to the next Monday without a notification
- **AND** the user must re-schedule via "Schedule" to set a new notification

### Requirement: Consistent across all views

The "Next Week" option SHALL appear in all views that show task context menus.

#### Scenario: Available in Today view

- **WHEN** the user is in the Today view and long-presses a task
- **THEN** "Next Week" appears in the context menu (after "Tomorrow", before "Later")

#### Scenario: Available in Tomorrow view

- **WHEN** the user is in the Tomorrow view and long-presses a task
- **THEN** "Next Week" appears in the context menu

#### Scenario: Available in Upcoming view

- **WHEN** the user is in the Upcoming view and long-presses a task
- **THEN** "Next Week" appears in the context menu

#### Scenario: Available in List detail view

- **WHEN** the user is in a list detail view and long-presses a task
- **THEN** "Next Week" appears in the context menu
