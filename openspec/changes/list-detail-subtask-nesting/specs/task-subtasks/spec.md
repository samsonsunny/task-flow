## Updated Requirements

The `task-subtasks` spec has been updated with two new requirements:

### Requirement: One-level depth cap
- Subtasks (tasks with `parentTask != nil`) cannot have their own subtasks
- The editor hides the "Add Subtask" section for subtasks

### Requirement: Drag-and-drop reparenting across parents
- When reparenting via drag-drop, the dragged task is removed from its old parent's `subtasks` array
- New scenario: "Drag subtask to reparent under different parent" covers the cross-parent case

### Requirement: Subtask creation via editor (clarified)
- The "Add Subtask" section is only shown for root tasks (no `parentTask`)
- Subtasks do not show the "Add Subtask" section

These additions enforce the one-level depth cap and ensure cross-parent reparenting maintains data consistency.
