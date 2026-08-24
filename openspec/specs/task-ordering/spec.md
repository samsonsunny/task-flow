# task-ordering

## Purpose

Define how task order is established and changed: drag-to-reorder in Today/Tomorrow (persisted per-day, independent of list order), drag-to-reorder within custom lists (fractional string sort order), and the Move to Top/Bottom context-menu shortcuts.

Consolidates (2026-08): `daily-reorder`, `custom-list-reorder`, `task-actions`.

## Requirements

### Requirement: Drag-to-reorder in Today view
The user SHALL be able to reorder root tasks in the Today view by long-pressing and dragging. The order SHALL persist across app restarts using UserDefaults.

#### Scenario: Drag reorders root tasks in Today
1. Given the Today view shows root tasks [A, B, C]
2. When the user drags B above A
3. Then the Today view shows [B, A, C]
4. And the order persists after app restart

#### Scenario: Children follow parent
1. Given the Today view shows root task A with subtasks A.1 and A.2
2. When the user drags A above another root task
3. Then A.1 and A.2 remain nested under A

### Requirement: Drag-to-reorder in Tomorrow view
The user SHALL be able to reorder root tasks in the Tomorrow view by long-pressing and dragging. The order SHALL persist across app restarts using UserDefaults.

#### Scenario: Drag reorders root tasks in Tomorrow
1. Given the Tomorrow view shows root tasks [D, E]
2. When the user drags E above D
3. Then the Tomorrow view shows [E, D]

### Requirement: Overdue section independent ordering
The Overdue section in the Today view SHALL have its own independent ordering, separate from Today's main tasks.

#### Scenario: Overdue and Today tasks have separate order
1. Given the Today view shows overdue tasks [O1, O2] and today tasks [T1, T2]
2. When the user reorders overdue tasks to [O2, O1]
3. Then today tasks remain in their existing order [T1, T2]

### Requirement: New daily tasks appear at end
Tasks without a stored order SHALL appear at the end of the list in their default date-sorted order.

#### Scenario: New task appears at bottom
1. Given the Today view shows reordered tasks [B, A, C]
2. When a new task D is created with today's due date
3. Then D appears after C (at the bottom)

### Requirement: List view order unaffected
Reordering in Today/Tomorrow views SHALL NOT affect the task's `sortOrder` property used in List views.

#### Scenario: List view preserves original order
1. Given task "Buy Milk" has `sortOrder` "m" in the "Shopping" list
2. When the user drags "Buy Milk" to the top of Today view
3. Then "Buy Milk" still appears at position "m" in the "Shopping" list

### Requirement: Tasks are reorderable via drag in custom lists
The system SHALL allow users to reorder tasks within any custom task list by dragging rows. The reordered position SHALL persist across app restarts.

Smart segments (Today, Tomorrow, Upcoming, Later, Overdue) SHALL NOT support drag-and-drop reordering — their task order SHALL remain algorithmically determined by `dueDate` then `createdAt` descending.

#### Scenario: Drag reorders a single task in a custom list
- **WHEN** the user long-presses and drags a task row to a new position within the same custom list
- **THEN** the task SHALL appear at the dropped position
- **AND** all other tasks SHALL remain in their relative positions
- **AND** the new order SHALL persist after relaunching the app

#### Scenario: Multi-select drag reorders multiple tasks
- **WHEN** the user selects multiple tasks and drags them to a new position
- **THEN** the selected tasks SHALL appear at the dropped position in their original relative order
- **AND** unselected tasks SHALL remain in their relative positions

#### Scenario: Smart segments show no reorder affordance
- **WHEN** the user views tasks in Today, Tomorrow, Upcoming, Later, or Overdue segments
- **THEN** the task rows SHALL NOT have drag handles or respond to drag gestures

### Requirement: Task sort order uses fractional string encoding
The system SHALL store each task's position as a `String` sortOrder using a lexicographic midpoint algorithm. Only the dragged task's sortOrder SHALL be updated per drag operation (no full-list re-index). The sortOrder SHALL be stored in a new `sortOrder` attribute on `TaskItem`.

#### Scenario: Single drag updates one record
- **WHEN** a task is dragged to a new position between two other tasks
- **THEN** the system SHALL update only that task's `sortOrder` in the database
- **AND** SHALL NOT modify `sortOrder` on any other task

#### Scenario: Midpoint string sorts correctly
- **WHEN** a task is dropped between two tasks with sortOrders "m" and "n"
- **THEN** the dragged task SHALL receive a sortOrder string that sorts lexicographically between "m" and "n" (e.g., "mm")

### Requirement: New tasks append to end of list
When a task is created in a custom list, the system SHALL assign it a sortOrder that places it after all existing tasks in that list.

#### Scenario: New task appears at bottom
- **WHEN** a user creates a new task in a custom list
- **THEN** the task SHALL appear as the last item in that list
- **AND** all existing task positions SHALL remain unchanged

### Requirement: Rare adjacency exhaustion handled locally
When the midpoint algorithm cannot produce a valid string between two adjacent sort orders, the system SHALL re-index only the immediately affected tasks (predecessor, dragged task, successor) to create room. This SHALL affect at most 3 tasks.

#### Scenario: Local widen on exhaustion
- **WHEN** a task is dragged between two tasks whose sortOrders have no valid midpoint
- **THEN** the system SHALL widen the gap by modifying the predecessor's or successor's sortOrder
- **AND** the dragged task SHALL receive a sortOrder between the widened bounds
- **AND** no more than 3 tasks SHALL have their sortOrder modified

### Requirement: Existing tasks backfilled on migration
On first launch after the update, all existing tasks SHALL receive an initial sortOrder based on their current `createdAt` order within each custom list. Smart segment tasks SHALL receive a `nil` sortOrder and their display order SHALL remain unchanged.

#### Scenario: Existing tasks get sequential sortOrder
- **WHEN** the app launches after the update
- **THEN** every existing task in a custom list SHALL have a non-nil `sortOrder`
- **AND** sortOrder values SHALL respect the task's creation order (oldest tasks first)

### Requirement: Move to Top action
The user SHALL be able to move a task to the top of its ordering context via a single tap in the context menu.

#### Scenario: Move root task to top of list
1. Given a list with root tasks [A, B, C] (in that order)
2. When the user long-presses C and taps "Top"
3. Then the list shows [C, A, B]
4. And the order persists across app restarts

#### Scenario: Move child task to top of siblings
1. Given root task A has children [X, Y, Z]
2. When the user long-presses Z and taps "Top"
3. Then A's children show [Z, X, Y]
4. And Z remains a child of A

### Requirement: Move to Bottom action
The user SHALL be able to move a task to the bottom of its ordering context via a single tap in the context menu.

#### Scenario: Move root task to bottom of list
1. Given a list with root tasks [A, B, C]
2. When the user long-presses A and taps "Bottom"
3. Then the list shows [B, C, A]

#### Scenario: Move child task to bottom of siblings
1. Given root task A has children [X, Y, Z]
2. When the user long-presses X and taps "Bottom"
3. Then A's children show [Y, Z, X]

### Requirement: Hide when single task
The "Top" and "Bottom" actions SHALL NOT appear when the task is the only one in its ordering context.

#### Scenario: Single root task hides actions
1. Given a list with only one root task A
2. When the user long-presses A
3. Then "Top" and "Bottom" do not appear in the context menu

#### Scenario: Single child hides actions
1. Given root task A has only one child X
2. When the user long-presses X
3. Then "Top" and "Bottom" do not appear in the context menu

### Requirement: List view scope for Top/Bottom actions
The "Top" and "Bottom" actions SHALL only appear in list views (DetailView), not in daily views (Today/Tomorrow).

#### Scenario: Actions hidden in Today view
1. Given the user is in the Today view
2. When the user long-presses a task
3. Then "Top" and "Bottom" do not appear in the context menu
