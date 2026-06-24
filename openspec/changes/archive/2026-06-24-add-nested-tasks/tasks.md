## 1. Data Model & Migration

- [x] 1.1 Add `parentTask` and `subtasks` relationships to `TaskItem` in `TaskFlowSchemaV6`
- [x] 1.2 Add `TaskFlowSchemaV6` to `TaskFlowMigrationPlan` with lightweight migration from V5
- [x] 1.3 Update the typealias `TaskItem` to point to V6

## 2. Recursive Task Node View

- [x] 2.1 Create `TaskNodeView` — a view that renders a `TaskRowView` for the current task and passes nesting info
- [x] 2.2 Add leading indentation proportional to depth (`depth * 20` pts)
- [x] 2.3 Add collapse/expand chevron to `TaskRowView` for parent tasks

## 3. Collapse State Management

- [x] 3.1 Add `collapsedTasks: Set<PersistentIdentifier>` state in `ListDetailView`
- [x] 3.2 Wire collapse/expand toggle to add/remove from the collapsed set
- [x] 3.3 Animate collapse/expand transitions (handled by List insertion/deletion animations)

## 4. List Hierarchy Rendering

- [x] 4.1 Replace flat `ForEach` in `ListDetailView` with hierarchy-flattened list using `FlatTaskNode`
- [x] 4.2 Pass collapse state and toggle action through the view hierarchy
- [ ] 4.3 Persist collapse state across view reloads (optional, nice to have)

## 5. Drag-and-Drop Reparenting

- [x] 5.1 Detect drop zones on task rows (upper half = sibling, lower half = child) via `TaskDropDelegate`
- [x] 5.2 Implement `onDrop` handler that reparents the dragged task
- [x] 5.3 Update sort order using `midpoint` algorithm for new sibling group
- [x] 5.4 Support dragging subtask to root level (flatten) via list-level onDrop
- [ ] 5.5 Add visual drop target indicator

## 6. Completion Cascade

- [x] 6.1 Add recursive `completeDescendants()` method on `TaskItem`
- [x] 6.2 Add recursive `uncompleteDescendants()` method on `TaskItem`
- [x] 6.3 Wire completion toggle in `ListDetailView` to cascade to descendants
- [x] 6.4 Cancel descendant notifications on cascade completion

## 7. Delete Cascade

- [x] 7.1 Add recursive `deleteDescendants()` method on `TaskItem`
- [x] 7.2 Wire delete action to cascade to all descendants
- [x] 7.3 Cancel descendant notifications on cascade delete

## 8. Subtask Count Badge

- [x] 8.1 Compute direct subtask count for parent tasks
- [x] 8.2 Display subtask count in `TaskRowView` metadata line (e.g., "3 ›")
- [x] 8.3 Update count in real-time when subtasks are added/removed

## 9. Segment View Flat Rendering

- [x] 9.1 Ensure `ReminderSegmentLogic.filteredTasks()` returns subtasks with due dates as flat rows
- [x] 9.2 Suppress indentation and collapse controls when rendering in segment views
- [x] 9.3 Verify subtasks without due dates are excluded from segment views

## 10. Editor Subtask Support

- [x] 10.1 Add "Add Subtask" control to `ReminderEditorView`
- [x] 10.2 Implement inline subtask creation (title field + submit)
- [x] 10.3 Set `parentTask`, `reminderList`, and default date on new subtask
- [x] 10.4 Show existing subtasks in the editor section

## 11. Schema Backward Compatibility

- [x] 11.1 Verify existing V3 stores migrate cleanly to V6 (lightweight migration, additive schema)
- [x] 11.2 Ensure existing data (tasks, lists, tags) is preserved after migration (lightweight, no transform)
- [x] 11.3 Test that `sortOrder` is maintained for both top-level and subtask siblings
