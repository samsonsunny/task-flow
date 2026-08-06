## ADDED Requirements

### Requirement: Unified due date context menu items
The task context menu SHALL present due-date scheduling actions inside a single "Deadline" submenu (Apple Reminders approach: every date action is two taps). The "Deadline" submenu SHALL list "None" first (no leading icon), then a divider, then the presets in order — Today, Tomorrow, This Weekend, Next Week — and Custom…. Each preset row SHALL show a leading calendar icon bearing the preset's target day-of-month. No flat Today / Tomorrow / Next Week / Next Month / Later / Schedule items SHALL appear outside this layout.

#### Scenario: Root task shows due date actions
- **WHEN** the user long-presses a task row in a time tab or list detail
- **THEN** the context menu SHALL contain a "Deadline" submenu
- **AND** the "Deadline" submenu SHALL list None, a divider, then Today, Tomorrow, This Weekend, Next Week, and Custom…
- **AND** the "Deadline" submenu SHALL NOT list a Next Month preset
- **AND** each preset row (Today, Tomorrow, This Weekend, Next Week) SHALL show a leading calendar icon with its target day-of-month

#### Scenario: The active due date is marked with a checkmark
- **WHEN** the user opens the context menu for a task
- **THEN** exactly one item SHALL be marked with a leading checkmark: "None" when the task has no due date; the preset whose target day equals the task's due date (compared at date level, time ignored); Custom… when the task has a due date that matches no preset
- **AND** every other item SHALL be listed without a checkmark (no item is hidden based on the current due date)

#### Scenario: Overdue and undated tasks show all presets
- **WHEN** the user opens the context menu for a task with no due date or an overdue due date
- **THEN** every preset (Today, Tomorrow, This Weekend, Next Week, and Custom…) SHALL be listed
- **AND** "None" SHALL be marked with a checkmark when the task has no due date
- **AND** Custom… SHALL be marked with a checkmark when the task has a due date that matches no preset (e.g. an overdue date)

### Requirement: None clears the due date
Tapping "None" in the "Deadline" submenu SHALL clear the task's due date (`dueDate = nil`) and cancel any scheduled notification for the task. The task SHALL then disappear from time tabs and remain visible only in its list.

#### Scenario: None removes task from time tabs
- **WHEN** a task in the Today tab has a due date
- **AND** the user opens its context menu and taps "None"
- **THEN** the task's dueDate SHALL be nil
- **AND** the task SHALL disappear from the Today tab
- **AND** the task SHALL remain visible in its list

#### Scenario: None cancels the notification
- **WHEN** a task with a scheduled time notification is cleared via "None"
- **THEN** the task's local notification SHALL be cancelled

### Requirement: Today and Tomorrow presets
Tapping "Today" SHALL set the due date to the start of the current day. Tapping "Tomorrow" SHALL set the due date to the start of the next calendar day.

#### Scenario: Today preset
- **WHEN** the user taps "Today" for a task
- **THEN** the task's dueDate SHALL be the start of the current day
- **AND** the task SHALL appear in the Today tab

#### Scenario: Tomorrow preset
- **WHEN** the user taps "Tomorrow" for a task
- **THEN** the task's dueDate SHALL be the start of the next calendar day
- **AND** the task SHALL appear in the Tomorrow tab

### Requirement: This Weekend preset
Tapping "This Weekend" SHALL set the due date to the upcoming Saturday (or today when the current day is Saturday or Sunday).

#### Scenario: Mid-week selection
- **WHEN** the current day is a weekday
- **AND** the user taps "This Weekend"
- **THEN** the task's dueDate SHALL be the upcoming Saturday

#### Scenario: Already in the weekend
- **WHEN** the current day is Saturday or Sunday
- **AND** the user taps "This Weekend"
- **THEN** the task's dueDate SHALL be the current day

### Requirement: Next Week preset
Tapping "Next Week" SHALL set the due date to the upcoming Monday, matching the existing `nextMonday` behavior.

#### Scenario: Next Week moves to Monday
- **WHEN** the user taps "Next Week"
- **THEN** the task's dueDate SHALL be the next upcoming Monday
- **AND** the task SHALL appear in the Upcoming tab

### Requirement: Custom opens the schedule sheet auto-focused
Tapping "Custom…" SHALL present the schedule sheet. When the task has no due date, the date picker SHALL be expanded on presentation. When the task already has a due date, the time picker SHALL be expanded on presentation.

#### Scenario: No date focuses date picker
- **WHEN** a task without a due date opens "Custom…"
- **THEN** the schedule sheet SHALL appear with the date picker already expanded
- **AND** the user SHALL not need to toggle anything to pick a date

#### Scenario: Existing date focuses time picker
- **WHEN** a task that already has a due date opens "Custom…"
- **THEN** the schedule sheet SHALL appear with the time picker already expanded

### Requirement: Due date actions apply in all contexts
The due date actions (the "Deadline" submenu with None, presets, and Custom…) SHALL be available from every context where a task row's context menu is shown (Today, Tomorrow, Upcoming, Overdue, and list detail).

#### Scenario: Actions present in list detail
- **WHEN** the user long-presses a task row in a list detail view
- **THEN** the "Deadline" submenu SHALL be present in the context menu

### Requirement: Move to List excludes the current list
For a root task, the "Move to List" menu SHALL omit the list the task currently belongs to. For a subtask, all lists SHALL be listed (choosing the parent's list promotes the subtask in place).

#### Scenario: Root task does not list its own list
- **WHEN** the user opens "Move to List" for a root task in list detail
- **THEN** the task's current list SHALL NOT appear as a destination
- **AND** every other list SHALL appear

#### Scenario: Subtask lists every list
- **WHEN** the user opens "Move to List" for a subtask in the editor
- **THEN** every list SHALL appear, including the parent's list
