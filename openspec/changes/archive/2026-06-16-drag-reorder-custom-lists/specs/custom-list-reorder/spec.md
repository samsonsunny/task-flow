## ADDED Requirements

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

### Requirement: Sort order uses fractional string encoding

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
