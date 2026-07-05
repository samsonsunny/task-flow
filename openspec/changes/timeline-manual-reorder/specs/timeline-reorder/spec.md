## ADDED Requirements

### Requirement: Tasks are reorderable via drag in timeline views

The system SHALL allow users to reorder tasks within Today, Tomorrow, and Upcoming views by dragging rows. The reordered position SHALL persist across app restarts and SHALL be reflected in the task's `sortOrder`, making the ordering consistent with list detail views.

Reordering in a timeline view operates on all visible tasks within that view, regardless of which list they belong to. The dragged task's `sortOrder` is computed as a midpoint between its new neighbors' sortOrders using the same LexoRank algorithm used in list detail reordering.

#### Scenario: Drag reorders a single task in Today view
- **WHEN** the user long-presses and drags a task row to a new position within the Today view
- **THEN** the task SHALL appear at the dropped position
- **AND** all other tasks SHALL remain in their relative positions
- **AND** the new order SHALL persist after relaunching the app
- **AND** the task's `sortOrder` SHALL be updated to reflect the new position

#### Scenario: Drag reorders across lists in a timeline view
- **WHEN** the user drags a task from one list to a new position between tasks from a different list in a timeline view
- **THEN** the task SHALL appear at the dropped position in the timeline view
- **AND** the task's position within its home list SHALL also be updated to reflect the new sortOrder
- **AND** no other tasks' sortOrders SHALL be modified (except local widen if needed)

#### Scenario: Reordered task retains position after due date unchanged
- **WHEN** the user reorders a task in a timeline view
- **AND** the task's due date does not change
- **THEN** the task SHALL remain at its dragged position across view refreshes

#### Scenario: Drag handles appear on timeline task rows
- **WHEN** the user views tasks in Today, Tomorrow, or Upcoming views
- **THEN** the task rows SHALL respond to drag gestures (long-press to initiate drag)
- **AND** each row SHALL show a drag affordance

### Requirement: Sort order is the primary sort key in timeline views

`ReminderSegmentLogic.sortedTasks` SHALL sort by `sortOrder` (lexicographic, ascending) as the primary key. Tasks without a `sortOrder` SHALL be sorted by the existing algorithmic fallback: `dueDate` ascending, then `createdAt` ascending, then `taskKey` ascending.

#### Scenario: Timeline sorts by sortOrder first
- **WHEN** a set of tasks is displayed in a timeline view
- **THEN** the tasks SHALL be ordered by `sortOrder` (ascending) first
- **AND** tasks with `sortOrder == nil` SHALL appear after all tasks with a non-nil sortOrder
- **AND** among tasks with `nil` sortOrder, the existing algorithmic sort (dueDate → createdAt → taskKey) SHALL apply

### Requirement: New tasks in timeline views append to end of view

When a task is created via quick capture in a timeline view, the system SHALL assign it a `sortOrder` that places it after all tasks currently visible in that view.

#### Scenario: Quick-captured task appears at bottom of timeline
- **WHEN** the user creates a new task via quick capture in a timeline view
- **THEN** the task SHALL appear as the last item in that view
- **AND** all existing task positions SHALL remain unchanged
