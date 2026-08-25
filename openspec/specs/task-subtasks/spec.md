## ADDED Requirements

### Requirement: Task has a parent-child relationship
A `TaskItem` SHALL support an optional self-referencing parent-child relationship. A task MAY have one parent task. A task MAY have zero or more child tasks. The relationship SHALL form a tree (no cycles).

#### Scenario: Create subtask via editor
- **WHEN** user opens `ReminderEditorView` for a task
- **AND** user adds a subtask in the subtask section
- **THEN** a new `TaskItem` is created with `parentTask` set to the parent task
- **AND** the new subtask appears indented under its parent in the list view

#### Scenario: Subtask has all task properties
- **WHEN** a subtask is created
- **THEN** it SHALL be a full `TaskItem` instance with all fields: title, notes, dueDate, priority, tags, reminders, url, sortOrder
- **AND** it SHALL support all operations that top-level tasks support

### Requirement: List view displays nested tasks hierarchically
`ListDetailView` SHALL display tasks in a hierarchical tree. Each subtask SHALL be indented relative to its parent. Parent tasks with children SHALL show a collapse/expand control. The default state for a parent SHALL be collapsed.

#### Scenario: Subtasks indent under parent
- **WHEN** a task has subtasks
- **THEN** each subtask row SHALL be indented by `depth * 20` points from the leading edge
- **AND** subtasks SHALL appear immediately below their parent in order

#### Scenario: Collapse hides subtasks
- **WHEN** user taps the collapse control on a parent task
- **THEN** all descendant subtasks SHALL be hidden with animation
- **AND** the collapse control SHALL update to indicate collapsed state

#### Scenario: Expand shows subtasks
- **WHEN** user taps the expand control on a collapsed parent task
- **THEN** all descendant subtasks SHALL appear with animation
- **AND** the expand control SHALL update to indicate expanded state

#### Scenario: Deep nesting renders correctly
- **WHEN** a task hierarchy has depth of N levels
- **THEN** each level SHALL indent by `depth * 20` points
- **AND** the list SHALL render correctly up to any depth (no truncation)

#### Scenario: Subtasks are collapsed by default on view load
- **WHEN** the list view loads for the first time
- **THEN** all parent tasks with subtasks SHALL have their subtask trees collapsed
- **AND** the user SHALL see only the parent task rows (no subtasks visible)
- **AND** the collapse control SHALL indicate collapsed state for each parent

### Requirement: Parent completion cascades to subtasks
When a parent task is marked as completed, all descendant subtasks SHALL also be marked as completed. When a parent task is uncompleted, all descendant subtasks SHALL also be uncompleted.

#### Scenario: Complete parent completes all descendants
- **WHEN** user completes a parent task that has subtasks
- **THEN** the parent task SHALL be marked completed
- **AND** all descendant subtasks at any depth SHALL be marked completed
- **AND** all descendant subtasks SHALL have their `completionDate` set
- **AND** all descendant subtask notifications SHALL be cancelled

#### Scenario: Uncomplete parent uncompletes all descendants
- **WHEN** user uncompletes a parent task (reverts completion)
- **THEN** the parent task SHALL be marked not completed
- **AND** all descendant subtasks at any depth SHALL be marked not completed
- **AND** all descendant subtasks SHALL have their `completionDate` set to nil

#### Scenario: Completing all subtasks does not auto-complete parent
- **WHEN** user completes the last incomplete subtask of a parent
- **THEN** the parent task SHALL remain in its current state (not auto-completed)

### Requirement: Delete parent cascades to subtasks
When a parent task is deleted, all its descendant subtasks SHALL also be deleted. This SHALL happen at all levels of the hierarchy.

#### Scenario: Delete parent deletes all descendants
- **WHEN** user deletes a task that has subtasks
- **THEN** the task SHALL be deleted
- **AND** all descendant subtasks at any depth SHALL also be deleted
- **AND** all associated notifications SHALL be cancelled

### Requirement: Subtask notifications operate independently
A subtask with its own `dueDate` and time component SHALL have its own local notification, independent of its parent's notification.

#### Scenario: Subtask gets own notification
- **WHEN** a subtask has a due date with time
- **THEN** a local notification SHALL be scheduled for that subtask independently
- **AND** completing the parent SHALL cancel the subtask's notification (via cascade completion)

### Requirement: Task row shows subtask count
When a task has subtasks, the task row SHALL display a subtask count indicator (e.g., "3 ▸") in the metadata line. The indicator SHALL show the number of direct subtasks.

#### Scenario: Subtask count visible on parent row
- **WHEN** a task has 3 direct subtasks
- **THEN** the metadata line SHALL show "3 ▸" or equivalent indicator
- **AND** the indicator SHALL update when subtasks are added or removed

### Requirement: One-level depth cap
A task that is already a subtask (has a non-nil `parentTask`) SHALL NOT be allowed to have subtasks of its own. The editor SHALL not show the "Add Subtask" section for subtasks.

#### Scenario: Subtask cannot add subtasks
- **WHEN** user opens the editor for a task that has a `parentTask`
- **THEN** the "Add Subtask" section SHALL NOT be shown

#### Scenario: Root task shows subtask section
- **WHEN** user opens the editor for a task with no `parentTask`
- **THEN** the "Add Subtask" section SHALL be shown as normal

### Requirement: Drag-and-drop supports reparenting
Drag-and-drop within `ListDetailView` SHALL support reparenting a task. Dropping a task onto another task's row SHALL make the dropped task a subtask of the target task. When reparenting, the dragged task SHALL be removed from its old parent's `subtasks` array.

#### Scenario: Drag task to become subtask
- **WHEN** user drags a task over another task's row
- **AND** drops on the lower half of the target row
- **THEN** the dragged task SHALL become a subtask of the target task
- **AND** the dragged task SHALL appear as the last child

#### Scenario: Drag subtask to reparent under different parent
- **WHEN** user drags a subtask onto a different root task's row
- **AND** drops on the lower half of the target root task
- **THEN** the subtask SHALL be removed from its old parent's `subtasks` array
- **AND** the subtask SHALL become a subtask of the target root task
- **AND** the subtask SHALL appear as the last child of the new parent

#### Scenario: Drag subtask to flatten it
- **WHEN** user drags a subtask
- **AND** drops it at the top level (above all tasks)
- **THEN** the subtask SHALL be removed from its parent
- **AND** the subtask SHALL become a top-level task

#### Scenario: Reorder siblings via drag
- **WHEN** user drags a subtask within its sibling group
- **THEN** the subtask SHALL be reordered among its siblings
- **AND** the sort order SHALL be updated via the existing `midpoint` algorithm

### Requirement: Segment views show subtasks flat
Reminder segment views (Today, Tomorrow, Upcoming, Later, Overdue) SHALL show subtasks independently as flat rows. Subtasks with their own due dates SHALL appear in the appropriate segment. Subtasks without due dates SHALL NOT appear in segment views.

#### Scenario: Subtask with due date appears in Today
- **WHEN** a subtask has a due date of today
- **THEN** it SHALL appear in the Today segment as a flat row
- **AND** it SHALL NOT display indentation or collapse controls

#### Scenario: Subtask without due date does not appear
- **WHEN** a subtask has no due date
- **THEN** it SHALL NOT appear in any segment view (Today, Upcoming, Later, Overdue)
- **AND** the list view remains the only place to see it

### Requirement: Subtask creation via editor
The `ReminderEditorView` SHALL support adding subtasks to the task being edited. A "Add Subtask" control SHALL be available in the editor for root tasks only. Subtasks (tasks with a `parentTask`) SHALL NOT show the "Add Subtask" section.

#### Scenario: Add subtask from editor
- **WHEN** user opens the editor for a root task (no `parentTask`)
- **AND** taps "Add Subtask"
- **THEN** a new inline subtask row appears in the editor
- **AND** the subtask can be titled and saved inline

#### Scenario: Subtask editor hides subtask creation
- **WHEN** user opens the editor for a subtask (has `parentTask`)
- **THEN** the "Add Subtask" section SHALL NOT be visible
