## Why

Subtasks are currently invisible in time tabs (Today/Tomorrow/Upcoming) unless they have their own due date. Undated children never appear, and even dated children render as flat rows with no hierarchy context. Users building structured task hierarchies (projects with checklists, multi-step tasks) lose that structure as soon as they switch from list view to a time tab.

## What Changes

- **Time tabs render subtasks inline** under their parent with full hierarchy (indentation, collapse/expand chevrons), matching the existing list detail UX
- **Two core rules** govern display:
  1. When a parent passes a time tab's filter, ALL descendants appear inline (regardless of their own due dates), collapsible/expandable
  2. When a subtask independently passes a time tab's filter but its parent does not, it appears standalone at depth 0 — no parent context is pulled in
- **Deduplication within the same view**: A subtask that was already included via inline nesting under its parent is not shown as a standalone row
- **Shared `TaskTreeFlattener` utility** extracts the flatten/collapse logic from `ListDetailViewModel` so both views use the same code
- Collapse/expand state is **per-view** (separate sets for list vs each time tab)

## Capabilities

### New Capabilities
- *(none)*

### Modified Capabilities
- `task-subtasks`: Replace the flat-row requirement with inline nesting rules (parent-driven display, dedup within view, orphan subtasks standalone)
- `task-row-display`: Remove the segment-view suppression of nesting indicators (chevron, indentation, subtask count now apply in all views)
- `app-mental-model`: Update the mental model to reflect the final subtask-in-time-tabs decision

## Impact

- `ReminderSegmentViewModel` — new flattening pipeline, collapse state, dedup logic
- `ReminderSegmentDetailView` — pass hierarchy params to `TaskRowView`
- `ListDetailViewModel` — replace inline `flattenTasks`/`flattenNode` with shared `TaskTreeFlattener`
- New file: `TaskTreeFlattener.swift` (shared utility)
- `TaskRowView` — unchanged (already supports all needed params)
- Upcoming tab section grouping — must work with tree-flattened input (subtrees crossing section boundaries)
