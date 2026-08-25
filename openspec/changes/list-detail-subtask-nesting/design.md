## Context

`ListDetailView` renders tasks from a list using `TaskTreeFlattener.flatten(roots:collapsed:nestSubtasks:)`. The flattener already supports nested mode (recursing into subtasks, assigning `depth` values), but `DetailViewModel.recompute()` passes `nestSubtasks: false`, producing a flat list where subtasks are invisible except for a "2/3" fraction on parent rows.

`AppState` already has `collapsedTasks: Set<PersistentIdentifier>` and `toggleTaskCollapsed()` with `UserDefaults` persistence — but no view calls them. `TaskRowView` has no chevron or expand/collapse UI.

The `task-row-display` spec already defines: chevron at trailing edge, depth-based indentation (20pt per level), expanded 44×44pt hit targets, and the subtask count metadata. The `task-subtasks` spec defines: hierarchical nesting in ListDetailView, collapse/expand with animation, default-collapsed state.

## Goals / Non-Goals

**Goals:**
- Enable nested subtask display in `ListDetailView` matching the spec behavior
- Persist collapse/expand state across sessions via `UserDefaults`
- Maintain all existing interactions: drag-drop reparenting, onMove reorder, swipe actions, context menus, bulk operations
- Animated collapse/expand transitions

**Non-Goals:**
- Depth capping (enforcing one-level max) — separate concern, not in this change
- Completion cascade (`completeDescendants`) — separate gap (Req 3)
- Delete cascade in `ReminderSegmentViewModel` — separate gap (Req 4)
- Changing time tab behavior — they stay flat per spec

## Decisions

### 1. Manual chevron + depth padding (Option B) over DisclosureGroup

**Choice:** Add a trailing chevron icon and `padding(.leading, depth * 20)` to each `taskListRow`, keeping the flat `ForEach(vm.flatNodes)` rendering.

**Alternatives considered:**
- **DisclosureGroup** (like Later tab groups): Rejected because `DisclosureGroup` in `List` conflicts with swipe actions, context menus, and `onMove` across group boundaries. Per-task `Binding<Bool>` mapped to `AppState.collapsedTasks` adds complexity. The Later tab uses `DisclosureGroup` at the section level (one per group), not at the individual row level (one per task).

**Rationale:** Minimal restructuring — `FlatTaskNode` already carries `depth`, `TaskTreeFlattener` already supports nesting. Just flip the flag and add UI.

### 2. Chevron in TaskRowView, not DetailView

**Choice:** Add `isExpanded` and `onToggleExpand` parameters to `TaskRowView` and render the chevron inside the row component.

**Rationale:** Keeps the row self-contained. `TaskRowView` is used in both `ListDetailView` and timeline views — the chevron parameters are optional with nil defaults, so timeline views are unaffected. The `isSelecting` state suppresses the chevron tap.

### 3. Wire through AppState environment

**Choice:** Add `@Environment(AppState.self)` to `DetailView` and pass `appState.collapsedTasks` to `viewModel?.update(...)`.

**Rationale:** `AppState` is already injected by `MainTabView`. Other views (`TimelineView`, `EditorView`, `CompletedView`) already use this pattern. No new infrastructure needed.

### 4. Depth indentation at the row level, not the flattener

**Choice:** Apply `padding(.leading, CGFloat(node.depth) * 20)` in `DetailView.taskListRow()`, not inside `TaskTreeFlattener`.

**Rationale:** The flattener produces data (depth value), the view decides how to render it. Time tabs use the same flattener output with `depth: 0` — they don't need indentation. Keeping indentation in the view layer avoids passing flags through the flattener.

## Risks / Trade-offs

- **[Risk] `onMove` reorder with nested nodes** → `flatToTaskIndex()` maps flat indices back to task indices via `persistentModelID`. With nested nodes the flat list has more entries, but the mapping is still correct. Children stay children after reorder; `recompute()` re-flattens the tree. Verified by tracing through the code.

- **[Risk] Drag-drop reparenting visual feedback** → `.onDrag`/`.onDrop` operate on individual `taskListRow` nodes regardless of depth. The `handleDrop` logic already handles parent/child relationships. No change needed.

- **[Risk] Selection mode conflict** → Chevron must not be tappable during `isSelecting`. Pass `nil` for `onToggleExpand` when `isSelecting` is true.

- **[Trade-off] Default collapsed** → Spec says default state is collapsed. `AppState.collapsedTasks` starts empty (all expanded). Need to initialize with all parent task IDs on first load, or invert the logic (store expanded IDs instead). Current `AppState` stores collapsed IDs, so first load shows everything expanded. To match spec, populate `collapsedTasks` with all parent IDs on first launch.

- **[Trade-off] Subtask count format** → Spec says "3 ▸" but implementation shows "2/3" (completed/total). Keeping "2/3" as it provides more information. The chevron replaces the ▸ indicator.
