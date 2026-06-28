## ADDED Requirements

### Requirement: ViewModel owns segment filtering and sorting
The ViewModel SHALL filter and sort tasks according to the active `ReminderSegment`, delegating to `ReminderSegmentLogic` for the computation.

#### Scenario: Filtered tasks computed from segment
- **WHEN** the ViewModel receives an updated task list and segment
- **THEN** `filteredTasks` SHALL contain tasks matching the segment's filter criteria, computed via `ReminderSegmentLogic.filteredTasks`

#### Scenario: Sorted tasks computed for flat segments
- **WHEN** the segment is Today, Tomorrow, Later, or Overdue
- **THEN** `sortedFlatTasks` SHALL contain tasks sorted via `ReminderSegmentLogic.sortedTasks`

### Requirement: ViewModel owns date grouping
The ViewModel SHALL compute `groupedSections` and `upcomingGroups` for segments that use grouped display.

#### Scenario: Grouped sections computed for dated segments
- **WHEN** the segment uses grouped sections
- **THEN** `groupedSections` SHALL be computed via `ReminderSegmentLogic.datedSections`

#### Scenario: Upcoming groups computed for upcoming segment
- **WHEN** the segment is Upcoming
- **THEN** `upcomingGroups` SHALL be computed via `ReminderSegmentLogic.upcomingGroups`

### Requirement: ViewModel owns completion lifecycle
The ViewModel SHALL handle task completion toggling with haptic feedback, `justCompleted` animation tracking, and notification cancellation. Behavior matches `ListDetailViewModel`.

#### Scenario: Toggle completion marks task
- **WHEN** `toggleCompletion(for:)` is called on an incomplete task
- **THEN** `task.isCompleted` SHALL be set to `true`, `task.completionDate` SHALL be set to now, and any pending notification SHALL be cancelled

### Requirement: ViewModel owns quick capture for segments
The ViewModel SHALL handle quick capture that assigns contextual date based on the active segment (today → today, tomorrow → tomorrow, upcoming → selected capture date).

#### Scenario: Quick capture assigns contextual date
- **WHEN** `commitQuickCapture(text:captureDate:)` is called in the Today segment
- **THEN** the new task's dueDate SHALL be set to the start of today

### Requirement: ViewModel owns scheduling and rescheduling
The ViewModel SHALL handle scheduling sheet commits and reschedule actions (Today, Tomorrow, Later), including notification management.

#### Scenario: Reschedule to today updates due date
- **WHEN** `rescheduleToToday(_:)` is called
- **THEN** the task's dueDate SHALL be set to the start of today and any existing notification SHALL be cancelled

#### Scenario: Schedule commit from sheet
- **WHEN** `scheduleTask(_:dueDate:hasTime:)` receives a date with time
- **THEN** the task's dueDate and hasTime SHALL be updated and a notification SHALL be scheduled

### Requirement: ViewModel provides timer refresh
The ViewModel SHALL expose a `refreshNow()` method that updates its internal `now` date, used by the view's timer publisher.

#### Scenario: Timer refresh updates now
- **WHEN** `refreshNow()` is called
- **THEN** the VM's `now` property SHALL be updated to the current date, and all derived state (filteredTasks, groupedSections) SHALL be recomputed
