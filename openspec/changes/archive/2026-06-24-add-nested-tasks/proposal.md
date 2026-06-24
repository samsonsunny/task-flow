## Why

TaskFlow currently treats all tasks as flat items. Users have no way to break down complex tasks into steps or group related tasks hierarchically. This limits the app's usefulness for project planning and daily checklists. Adding Apple Reminders-style nested subtasks brings TaskFlow closer to feature parity with the app it's modeled after.

## What Changes

- Add a self-referencing `parentTask` relationship on `TaskItem` to support hierarchical nesting of tasks
- Subtasks are full `TaskItem` instances — they retain their own due dates, priorities, tags, notes, and notifications
- List views show subtasks indented under their parent with a collapse/expand toggle
- Completing a parent task cascades completion to all its subtasks (but completing all subtasks does NOT auto-complete the parent)
- Deleting a parent task cascades to all its subtasks (cascade delete)
- Segment views (Today/Upcoming/Later/Overdue) show tasks independently regardless of nesting — a subtask with its own due date appears flat in the appropriate segment
- Drag-and-drop in list views supports reparenting: dragging a task onto another makes it a subtask; dragging a subtask to the root level flattens it
- Add a subtask count badge on parent rows (e.g., "3 ▸")

## Capabilities

### New Capabilities
- `task-subtasks`: Support for nesting tasks hierarchically — data model, UI recursion, collapse/expand, indent display

### Modified Capabilities
- `task-row-display`: Task rows need to communicate nesting depth, parent status (has children), and collapse/expand state
- `contextual-task-creation`: Quick capture and editor need to support creating subtasks (e.g., via `>` prefix or from the editor)

## Impact

- **Data model**: New `parentTask` inverse relationship on `TaskItem` + schema migration to V4
- **TaskRowView**: Needs to become `TaskNodeView` (recursive) or accept depth/indentation parameters
- **ListDetailView**: Flat `ForEach` replaced with recursive rendering; collapse state management; reparenting logic in drag-and-drop
- **ReminderSegmentDetailView**: Current segment views work with flat arrays — subtask grouping handled at the query level (flatten the hierarchy before filtering)
- **ReminderEditorView**: Add a subtask management section
- **ReminderDraft / ReminderDraftMapper**: No changes needed unless subtask creation flows through the draft
- **TaskUIModel / ReminderSegmentLogic**: Task filtering already works on flat `[TaskItem]` — subtask flattening needed at the query layer
