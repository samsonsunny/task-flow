## ADDED Requirements

### Requirement: Tests exist for all reorder orchestration

The system SHALL have a comprehensive test suite covering all ViewModel-level reorder methods. Each method SHALL have tests for its primary behavior, edge cases, and failure modes.

#### Scenario: midpoint utility edge cases tested
- **WHEN** `midpoint` is called with a nil lower bound and a non-nil upper bound that is the shortest possible string ("a")
- **THEN** the result SHALL be valid (non-nil) and sort less than "a"

#### Scenario: midpoint exhaustion triggers widen recovery
- **WHEN** tasks are repeatedly reordered between two adjacent sortOrders until midpoint returns nil
- **THEN** the widen path SHALL fire without crashing
- **THEN** all sortOrders SHALL remain unique and monotonically increasing after the operation

#### Scenario: moveTasks with single item from first to last
- **WHEN** a task at index 0 is moved to the last position in a list of 3+ tasks
- **THEN** the task SHALL appear at the end
- **AND** all tasks SHALL have non-nil sortOrders
- **AND** sortOrders SHALL be strictly increasing

#### Scenario: moveTasks with single item from last to first
- **WHEN** a task at the last index is moved to index 0 in a list of 3+ tasks
- **THEN** the task SHALL appear at the beginning
- **AND** all sortOrders SHALL be strictly increasing

#### Scenario: moveTasks with multiple items
- **WHEN** two non-adjacent tasks are selected (fromOffsets = [0, 2]) and moved to a new position
- **THEN** the moved tasks SHALL appear in their original relative order at the drop position
- **AND** all sortOrders SHALL be strictly increasing

#### Scenario: moveTasks with adjacent items
- **WHEN** two adjacent tasks are selected (fromOffsets = [2, 3]) and moved
- **THEN** the reversed-removal pattern SHALL correctly handle adjacency
- **AND** all sortOrders SHALL be strictly increasing

#### Scenario: moveTasks preserves all sortOrders when dropped at same position
- **WHEN** a task is moved to its current position (fromOffsets = [1], toOffset = 1)
- **THEN** no sortOrders SHALL change
- **AND** the task list SHALL be unchanged

#### Scenario: moveTasks widen path mutates upper task
- **WHEN** midpoint exhaustion occurs (midpoint returns nil)
- **AND** the widen path fires
- **THEN** the upper (successor) task SHALL have its sortOrder widened
- **AND** the widened value SHALL not collide with any existing sortOrder

### Requirement: handleDrop supports sibling reorder and reparenting

The `handleDrop` method SHALL correctly handle all drag-drop scenarios: reorder among siblings, reparent as child, cycle prevention, and self-drop.

#### Scenario: Drop on upper zone reorders among siblings
- **WHEN** a task is dragged and dropped on the upper half (y < threshold) of a sibling task
- **THEN** the dragged task SHALL be reordered to appear immediately before the target
- **AND** both tasks SHALL share the same parentTask

#### Scenario: Drop on lower zone makes child
- **WHEN** a task is dragged and dropped on the lower half (y >= threshold) of a target task
- **THEN** the dragged task SHALL become a subtask of the target
- **AND** the dragged task SHALL appear as the last child

#### Scenario: Drop task on itself is a no-op
- **WHEN** a task is dragged and dropped onto its own row
- **THEN** no changes SHALL occur (no reorder, no reparent, no crash)

#### Scenario: Drop parent onto descendant is prevented
- **WHEN** a parent task is dragged onto one of its descendant subtasks
- **THEN** the drop SHALL be rejected (no changes)
- **AND** the hierarchy SHALL remain unchanged

#### Scenario: Drop into task with existing subtasks
- **WHEN** a task is dropped onto a target that already has 3 subtasks
- **THEN** the dragged task SHALL become a child
- **AND** SHALL appear after all existing subtasks

#### Scenario: Drop into task with no subtasks
- **WHEN** a task is dropped onto a target with zero subtasks
- **THEN** the dragged task SHALL become the first child

### Requirement: moveTaskToRoot correctly unnests tasks

The `moveTaskToRoot` method SHALL correctly move a nested task back to root level and assign it a valid sortOrder among root siblings.

#### Scenario: Un-nest to empty root
- **WHEN** a nested task is moved to root in a list that has no other root-level tasks
- **THEN** the task SHALL have parentTask = nil
- **AND** SHALL receive a valid sortOrder

#### Scenario: Un-nest to root with existing siblings
- **WHEN** a nested task is moved to root in a list that has 3 root-level tasks
- **THEN** the task SHALL appear after all existing root tasks
- **AND** sortOrders SHALL remain strictly increasing

### Requirement: moveLists supports within-group and cross-group reorder

The `moveLists` method SHALL correctly reorder lists within a group and across groups.

#### Scenario: Move list within same group
- **WHEN** a list is dragged to a new position within its current group
- **THEN** the list SHALL appear at the new position
- **AND** the list SHALL remain in the same group

#### Scenario: Move list to different group
- **WHEN** a list is dragged from one group to another
- **THEN** the list SHALL appear at the new position in the target group
- **AND** the list SHALL be reassigned to the target group

#### Scenario: Move list to empty group
- **WHEN** a list is moved into a group that has no other lists
- **THEN** the list SHALL become the first (and only) list in that group
- **AND** SHALL receive a valid sortOrder

### Requirement: commitQuickCapture assigns sortOrder

The `commitQuickCapture` method SHALL assign a valid sortOrder to newly created tasks so they appear at the end of the list.

#### Scenario: Quick-captured task gets sortOrder
- **WHEN** a task is created via quick capture in a list with 3 existing tasks
- **THEN** the task SHALL have a non-nil sortOrder
- **AND** the sortOrder SHALL place it after all 3 existing tasks

#### Scenario: Quick-captured task in empty list gets sortOrder
- **WHEN** a task is created via quick capture in an empty list
- **THEN** the task SHALL have a non-nil sortOrder

### Requirement: isDescendant correctly identifies ancestry

The `isDescendant` method SHALL correctly identify parent-child relationships at all depths.

#### Scenario: Direct parent identified
- **WHEN** checking if a subtask is a descendant of its immediate parent
- **THEN** the result SHALL be true

#### Scenario: Grandparent identified
- **WHEN** checking if a subtask is a descendant of its grandparent (depth 2)
- **THEN** the result SHALL be true

#### Scenario: Unrelated task returns false
- **WHEN** checking if a task is a descendant of an unrelated task
- **THEN** the result SHALL be false

#### Scenario: Self returns false
- **WHEN** checking if a task is a descendant of itself
- **THEN** the result SHALL be false

### Requirement: SortOrder invariant property tests

The system SHALL have property-based tests that verify sortOrder invariants after any reorder operation.

#### Scenario: SortOrder uniqueness after moveTasks
- **WHEN** any `moveTasks` call completes
- **THEN** no two tasks in the same list SHALL have equal sortOrder strings

#### Scenario: SortOrder monotonicity after moveTasks
- **WHEN** any `moveTasks` call completes
- **THEN** the sortOrder strings SHALL be in strictly increasing lexicographic order

#### Scenario: No crash on repeated same-position inserts
- **WHEN** 100 tasks are sequentially inserted between the same two existing tasks
- **THEN** all operations SHALL complete without crash
- **AND** all sortOrders SHALL remain unique and monotonically increasing
