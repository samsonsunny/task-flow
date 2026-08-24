# Concept: Lists & Groups (Home Axis)

**Axis:** Home — where tasks live, independent of when they're due.
**Consolidated from (archived):** `mvvm-lists-tab.json`, `mvvm-list-detail.json`

## Purpose

Two screens own the "home" axis:

1. **Lists tab (Later tab root)** — CRUD for lists and groups, drag reorder, group membership, expand/collapse.
2. **List detail** — the task surface inside one list: nesting/subtasks, drag-drop reorder *and* re-parenting, quick capture, scheduling.

## Code map

| File | Role |
|---|---|
| `TaskFlow/Features/Lists/ListView.swift` + `ListViewModel.swift` | Tab root; all list/group operations |
| `TaskFlow/Features/Lists/DetailView.swift` + `DetailViewModel.swift` | Single-list task view |
| `TaskFlow/Features/Lists/ListCreationSheet.swift`, `GroupCreationSheet.swift`, `MiniCreationSheet.swift` | Creation dialogs |
| `TaskFlow/Utilities/SortOrderMidpoint.swift` | Shared midpoint/widen ordering |

## Responsibilities of ListViewModel

### Derived state (`update(lists:groups:allTasks:)`)
- `defaultList`, `ungroupedLists`, `listsInGroup(_:)`.
- All alert/dialog state lives here: creation flags + names, rename targets + text buffers, pending-delete references (for both lists and groups).

### Mutations
- **List CRUD:** `createList(name:)` (optionally into a group), `renameList(_:to:)`, `deleteList(_:moveTasksTo:)` (tasks survive → target list) vs `deleteListAndTasks(_:)`.
- **Group CRUD:** `createGroup(name:sourceList:)`, `renameGroup(_:to:)`, `deleteGroup(_:)` — **cascades**: deletes contained tasks and lists before the group itself.
- **Reorder:** `moveLists(fromOffsets:toOffset:in:group:)` and `moveGroups(fromOffsets:toOffset:)` using midpoint/widen.
- **Membership:** `assignListToGroup(_:group:)`.

## Responsibilities of DetailViewModel

### Derived state (`update(tasks:lists:allTasks:now:collapsedTasks:)`)
- Flat node list with collapse support (`recompute`, `siblings(of:)`).
- `justCompleted` animation tracking; `refreshNow()` timer hook.

### Mutations
- **Completion:** `toggleCompletion(for:)` with notification cancellation.
- **Quick capture:** `commitQuickCapture(text:notes:in:)`, `openQuickCaptureEditor(text:listID:)`.
- **Delete/move:** `delete(task:)`, `moveTask(_:to:)`, `assignSortOrder(for:in:)`.
- **Drag-drop:** `moveTasks(fromOffsets:toOffset:)` (flat reorder), `handleDrop(target:location:)` (nesting/re-parenting), `moveTaskToRoot()`, cycle guard `isDescendant(_:of:)`, plus `moveToTop/moveToBottom`.
- **Scheduling:** `presentScheduleSheet(for:)`, `scheduleTask(_:dueDate:hasTime:)`, reschedule shortcuts (Today/Tomorrow/None/Next Week/Weekend).
- **Bulk variants:** `bulkReschedule*`, `bulkMoveToList`, `bulkToggleCompletion`, `bulkDelete`, `bulkSetPriority`.

## Invariants worth preserving

1. **Cascade semantics are explicit, not implicit.** Deleting a list offers "move tasks to another list" OR "delete everything"; deleting a group always cascades to its lists and their tasks. Any new delete path must pick a side deliberately.
2. **A task can never become its own descendant.** All drop/re-parent paths must check `isDescendant(_:of:)` first.
3. **Sort order uses midpoint/widen only** (`SortOrderMidpoint`) — never renumber a whole sibling set to insert one item.
4. **Dialog state belongs in the VM.** Six alert flows were moved out of `@State` so they're testable without presentation.
5. **Group expand/collapse persists across restarts** (UserDefaults-backed `expandedGroupIDs`).

## History

Originally two refactors (June 2026): ListsTabView (~436 lines → VM with 6 alert flows) and ListDetailView (~526 lines → VM). Bulk operations and group-level reorder arrived later and live in these same ViewModels.
