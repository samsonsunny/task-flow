## ADDED Requirements

### Requirement: List detail displays tasks flat
`ListDetailView` SHALL display all tasks in a list as flat rows at a single indentation level. Hierarchy SHALL be visible only through the parent row's progress fraction and inside the editor. No indentation, chevron, or collapse/expand control SHALL be shown.

#### Scenario: Subtasks render without indentation
- **WHEN** a list contains a task with subtasks
- **THEN** every row SHALL render at depth 0
- **AND** no disclosure indicator or collapse control SHALL appear on any row

#### Scenario: Parent row shows completed/total fraction
- **WHEN** a parent task has N direct subtasks of which M are completed
- **THEN** the parent row's metadata line SHALL show "M/N"
- **AND** the fraction SHALL update when a subtask is added, removed, or toggled

### Requirement: Nesting depth is capped at one level
A subtask SHALL NOT have children. Every mutation point that can set `parentTask` — subtask creation in the editor and drag-and-drop reparenting in list detail — SHALL reject or redirect changes that would produce a task whose parent also has a parent. The relationship SHALL remain cycle-free at all times.

#### Scenario: Editor cannot add a subtask to a subtask
- **WHEN** the user opens the editor for a task that itself has a parentTask
- **THEN** the editor SHALL NOT offer an Add Subtask control

#### Scenario: Dropping onto a subtask cannot nest deeper
- **WHEN** a task is dropped onto a target row that already has a parentTask
- **THEN** the drop SHALL NOT create a child relationship with that target
- **AND** the dropped task SHALL be inserted as a sibling of the target instead

### Requirement: Legacy deep hierarchies are flattened
Hierarchies created before the one-level cap MAY exceed one level in stored data. The app SHALL flatten them: every task whose parent also has a parent SHALL be detached — its `parentTask` becomes nil, making it an independent top-level task. Flattening SHALL repeat until no such task remains and SHALL be idempotent (no work remains on subsequent passes).

#### Scenario: Grandchildren become independent top-level tasks
- **WHEN** flattening encounters Project > Phase > Step
- **THEN** Phase SHALL remain a subtask of Project at depth 1
- **AND** Step's parentTask SHALL become nil, making it an independent top-level task

#### Scenario: Flattening preserves everything except the parent link
- **WHEN** a task is detached during flattening
- **THEN** it SHALL keep its list membership, dueDate, priority, notes, tags, sortOrder, completion state, and notifications
- **AND** no notification SHALL be scheduled or cancelled by the detach alone

### Requirement: Explicit limitations (non-goals)
The following constraints SHALL hold permanently as deliberate product decisions, not defects: a subtask MUST NOT be creatable before its parent exists (the editor requires a saved task); a subtask SHALL always belong to its parent's list, and assigning it to another list SHALL promote it to a top-level task in that list; an undated subtask SHALL be invisible outside its list and the editor; a parent's due date and priority SHALL NOT derive from its subtasks; completing all subtasks SHALL NOT complete the parent; and the parent row fraction SHALL count direct subtasks only.

#### Scenario: Undated subtask stays out of time tabs
- **WHEN** a subtask has no due date
- **THEN** it SHALL NOT appear in any time tab or date-based surface
- **AND** it SHALL remain visible in its list and in the parent's editor section

#### Scenario: Moving a subtask to another list promotes it
- **WHEN** the user moves a subtask to a different list than its parent's
- **THEN** the subtask's parentTask SHALL become nil
- **AND** the subtask SHALL become a top-level task in the chosen list

## MODIFIED Requirements

### Requirement: Task has a parent-child relationship
A `TaskItem` SHALL support an optional self-referencing parent-child relationship. A task MAY have one parent task. A task MAY have zero or more child tasks — but a task that itself has a parent SHALL NOT have children (maximum nesting depth: one; see "Nesting depth is capped at one level"). The relationship SHALL form a tree (no cycles).

#### Scenario: Create subtask via editor
- **WHEN** user opens the editor for an existing saved task
- **AND** user adds a subtask in the subtask section
- **THEN** a new `TaskItem` is created with `parentTask` set to the parent task
- **AND** the subtask inherits the parent's reminder list

#### Scenario: Subtask has all task properties
- **WHEN** a subtask is created
- **THEN** it SHALL be a full `TaskItem` instance with all fields: title, notes, dueDate, priority, tags, reminders, url, sortOrder
- **AND** it SHALL support all operations that top-level tasks support

### Requirement: Parent completion cascades to subtasks
When a parent task is marked as completed, ALL its subtasks SHALL also be marked as completed, their `completionDate` set, and their notifications cancelled. When a parent task is uncompleted, all its subtasks SHALL also be uncompleted with `completionDate` cleared. Cascading applies recursively so legacy deeper hierarchies behave correctly during the flattening window. Completing all subtasks SHALL NOT auto-complete the parent.

#### Scenario: Complete parent completes all subtasks
- **WHEN** user completes a parent task that has subtasks
- **THEN** the parent task SHALL be marked completed
- **AND** all its subtasks SHALL be marked completed with `completionDate` set
- **AND** all subtask notifications SHALL be cancelled

#### Scenario: Uncomplete parent uncompletes all subtasks
- **WHEN** user uncompletes a parent task (reverts completion)
- **THEN** the parent task SHALL be marked not completed
- **AND** all its subtasks SHALL be marked not completed with `completionDate` cleared

#### Scenario: Completing all subtasks does not auto-complete parent
- **WHEN** user completes the last incomplete subtask of a parent
- **THEN** the parent task SHALL remain in its current state (not auto-completed)

### Requirement: Delete parent cascades to subtasks
When a parent task is deleted, all its subtasks SHALL also be deleted permanently. This SHALL hold at every deletion site: editor swipe/context menu, list detail single and bulk delete, time tab single and bulk delete, and the Completed view.

#### Scenario: Delete parent deletes all descendants from any surface
- **WHEN** user deletes a task that has subtasks (from the editor, list detail, a time tab, or Completed view)
- **THEN** the task SHALL be deleted
- **AND** all its subtasks SHALL also be deleted
- **AND** all deleted tasks' notifications SHALL be cancelled before deletion

#### Scenario: Bulk deletion follows the same rule
- **WHEN** user bulk-deletes a selection containing a parent task
- **THEN** that parent's subtasks SHALL be deleted along with it
- **AND** no orphaned subtasks SHALL remain in any list

### Requirement: Task row shows subtask count
When a task has subtasks, the task row SHALL display a progress fraction ("completed/total", e.g. "1/3") in the metadata line, counting direct subtasks only. The fraction SHALL update when subtasks are added, removed, or toggled.

#### Scenario: Fraction visible on parent row
- **WHEN** a task has 3 direct subtasks of which 1 is completed
- **THEN** the metadata line SHALL show "1/3"
- **AND** completing another subtask updates it to "2/3"

### Requirement: Drag-and-drop supports reparenting
Drag-and-drop within `ListDetailView` SHALL support reparenting a task. Dropping on the upper portion of a target row inserts the dragged task as a sibling of the target; dropping on the lower portion makes the dragged task a child of the target — only when the target does not itself have a parent (one-level cap; otherwise sibling insert applies). Dropping above all tasks promotes a subtask to top level. Sibling reorder uses the existing midpoint sort algorithm.

#### Scenario: Drag task to become subtask of a root task
- **WHEN** user drops a task on the lower portion of a root task's row
- **THEN** the dragged task SHALL become a subtask of the target
- **AND** the dragged task SHALL be positioned per the midpoint sort order among the target's children

#### Scenario: Drop on a subtask inserts as sibling
- **WHEN** user drops a task on the lower portion of a row whose target already has a parentTask
- **THEN** the dragged task SHALL be inserted as a sibling of that target (same parent)
- **AND** depth SHALL NOT exceed one level

#### Scenario: Drag subtask to flatten it
- **WHEN** user drags a subtask and drops it above all tasks
- **THEN** the subtask's parentTask SHALL become nil
- **AND** the subtask SHALL become a top-level task in the same list

#### Scenario: Reorder siblings via drag
- **WHEN** user drags a task within its sibling group
- **THEN** the task SHALL be reordered among its siblings
- **AND** sort orders SHALL be updated via the existing midpoint algorithm

### Requirement: Segment views show subtasks flat
Segment views (Today, Tomorrow, Upcoming, Overdue) SHALL show subtasks independently as flat standalone rows. Each task — top-level or subtask — qualifies for a segment solely by its own due date. Subtasks without due dates SHALL NOT appear in segment views. No inline nesting, indentation, or collapse controls SHALL be rendered.

#### Scenario: Dated subtask appears in Today
- **WHEN** a subtask has a due date of today
- **THEN** it SHALL appear in the Today segment as a flat row alongside top-level tasks

#### Scenario: Subtask without due date does not appear
- **WHEN** a subtask has no due date
- **THEN** it SHALL NOT appear in any segment view
- **AND** the list detail and editor remain the only places to see it

#### Scenario: Parent and subtask both dated render independently
- **WHEN** a parent and its subtask both have today's due date
- **THEN** each SHALL appear as its own flat row in Today (no inline nesting, no dedup suppression)

### Requirement: Subtask creation via editor
The editor SHALL be the only place to create subtasks, and only for an already-saved task. An "Add Subtask" control in the editor creates a full `TaskItem` inheriting the parent's reminder list, ordered via the midpoint sort algorithm. The editor SHALL NOT offer subtask creation when the edited task itself has a parentTask.

#### Scenario: Add subtask from editor
- **WHEN** user opens the editor for a saved task and taps "Add Subtask"
- **THEN** a new subtask appears in the editor's subtask section
- **AND** the subtask can be titled, scheduled, reordered, and managed like any task

#### Scenario: No creation during new-task authoring
- **WHEN** user is creating a brand-new task that has not been saved yet
- **THEN** the editor SHALL NOT show the subtask section

## REMOVED Requirements

### Requirement: List view displays nested tasks hierarchically
**Reason**: Reverted from the product (commit `72f901d`). List detail renders flat rows with a progress fraction; hierarchy is managed in the editor. Replaced by the ADDED requirement "List detail displays tasks flat".
