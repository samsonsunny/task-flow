## ADDED Requirements

### Requirement: Unified due date context menu items
The task context menu SHALL present due-date scheduling actions as flat top-level items — Today, Tomorrow, This Weekend — followed by "No Date" (only when the task has a due date), then the remaining presets (Next Week, Next Month, Custom…) inside a single "More" submenu. No flat Today / Tomorrow / Next Week / Later / Schedule items SHALL appear outside this layout.

#### Scenario: Root task shows due date actions
- **WHEN** the user long-presses a task row in a time tab or list detail
- **THEN** the context menu SHALL list Today, Tomorrow, This Weekend, and (when dated) No Date at the top level
- **AND** the context menu SHALL contain a "More" submenu
- **AND** the "More" submenu SHALL list Next Week, Next Month, and Custom…

#### Scenario: Due date actions adapt to the current due date
- **WHEN** the user opens the context menu for a task
- **THEN** the preset matching the task's current due date SHALL NOT be listed (e.g. "Today" is omitted for a task already due today, "Tomorrow" for a task due tomorrow)
- **AND** "No Date" SHALL be listed only when the task has a due date

#### Scenario: Overdue and undated tasks show all presets
- **WHEN** the user opens the context menu for a task with no due date or an overdue due date
- **THEN** every preset (Today, Tomorrow, This Weekend, and the "More" items) SHALL be listed
- **AND** "No Date" SHALL be omitted for a task with no due date

### Requirement: No Date clears the due date
Tapping "No Date" in the context menu SHALL clear the task's due date (`dueDate = nil`) and cancel any scheduled notification for the task. The task SHALL then disappear from time tabs and remain visible only in its list.

#### Scenario: No Date removes task from time tabs
- **WHEN** a task in the Today tab has a due date
- **AND** the user opens its context menu and taps "No Date"
- **THEN** the task's dueDate SHALL be nil
- **AND** the task SHALL disappear from the Today tab
- **AND** the task SHALL remain visible in its list

#### Scenario: No Date cancels the notification
- **WHEN** a task with a scheduled time notification is cleared via "No Date"
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

### Requirement: Next Month preset
Tapping "Next Month" SHALL set the due date to the same day-of-month in the next month. When that day does not exist in the next month (e.g. Jan 31), the due date SHALL clamp to the last day of that month.

#### Scenario: Same day next month
- **WHEN** a task is due on the 15th
- **AND** the user taps "Next Month"
- **THEN** the task's dueDate SHALL be the 15th of the next month

#### Scenario: Overflow clamps to month end
- **WHEN** a task is due on January 31
- **AND** the user taps "Next Month"
- **THEN** the task's dueDate SHALL be February 28 (or 29 in a leap year)

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
The due date actions (flat presets, "More" submenu, and No Date) SHALL be available from every context where a task row's context menu is shown (Today, Tomorrow, Upcoming, Overdue, and list detail).

#### Scenario: Actions present in list detail
- **WHEN** the user long-presses a task row in a list detail view
- **THEN** the flat due date presets and "More" submenu SHALL be present in the context menu

### Requirement: Move to List excludes the current list
For a root task, the "Move to List" menu SHALL omit the list the task currently belongs to. For a subtask, all lists SHALL be listed (choosing the parent's list promotes the subtask in place).

#### Scenario: Root task does not list its own list
- **WHEN** the user opens "Move to List" for a root task in list detail
- **THEN** the task's current list SHALL NOT appear as a destination
- **AND** every other list SHALL appear

#### Scenario: Subtask lists every list
- **WHEN** the user opens "Move to List" for a subtask in the editor
- **THEN** every list SHALL appear, including the parent's list
