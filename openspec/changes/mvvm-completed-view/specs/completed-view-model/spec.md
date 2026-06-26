## ADDED Requirements

### Requirement: ViewModel computes recent completed tasks
The ViewModel SHALL filter all tasks to those completed within the last 30 days, ordered by completion date descending.

#### Scenario: Recent tasks filtered by 30-day cutoff
- **WHEN** tasks are passed to `update(tasks:)`
- **THEN** `recentCompletedTasks` SHALL contain only tasks with `isCompleted == true` and `completionDate` within the last 30 days

### Requirement: ViewModel groups tasks by recency
The ViewModel SHALL group recent completed tasks into Today, Yesterday, This Week, and Earlier sections.

#### Scenario: Tasks grouped by completion date
- **WHEN** tasks have completion dates spanning multiple periods
- **THEN** `groupedTasks` SHALL contain tuples of section title and task arrays, sorted by recency

### Requirement: ViewModel handles un-complete
The ViewModel SHALL restore a completed task to active status, clearing its completion date and rescheduling any notification if the task has a time component.

#### Scenario: Un-complete restores task
- **WHEN** `uncomplete(_:)` is called
- **THEN** `task.isCompleted` SHALL be set to `false`, `task.completionDate` SHALL be set to `nil`, and a notification SHALL be scheduled if the task has a time component

### Requirement: ViewModel handles deletion
The ViewModel SHALL delete a completed task and cancel any pending notification.

#### Scenario: Delete cancels notification and removes task
- **WHEN** `delete(_:)` is called
- **THEN** any pending notification SHALL be cancelled and the task SHALL be deleted from the model context

### Requirement: ViewModel provides destination label
The ViewModel SHALL compute a human-readable label indicating where a task will reappear based on its due date.

#### Scenario: Destination for overdue task
- **WHEN** a task's due date is in the past
- **THEN** `destinationLabel(for:)` SHALL return "Was overdue"
