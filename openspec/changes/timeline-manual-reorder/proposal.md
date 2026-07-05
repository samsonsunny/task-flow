## Why

Users can manually reorder tasks within custom list detail views, but not in timeline views (Today/Tomorrow/Upcoming). This is inconsistent — the user's sense of priority should be actionable regardless of which tab they're in. Adding manual reorder to timeline views would let users prioritize across lists and due dates in one place.

This is not a trivial change: `sortOrder` is currently scoped to per-list ordering. Extending it to timeline views raises fundamental questions about whether ordering is global or view-dependent, and how cross-list reordering affects task positions within their home lists.

## What Changes

- Timeline views (Today, Tomorrow, Upcoming) gain drag-and-drop reorder affordance
- `ReminderSegmentLogic.sortedTasks` incorporates `sortOrder` as a primary or hybrid sort key, replacing pure algorithmic sort
- The midpoint/widen reordering algorithm is extracted into a shared utility used by both `DetailViewModel` and `ReminderSegmentViewModel`
- Quick capture in timeline views assigns a `sortOrder` consistent with the new ordering model
- Existing `custom-list-reorder` spec is modified to reflect that timeline views also support reorder

**Breaking/risky:** Cross-list reorder in timeline views may reposition tasks within their home lists in ways users don't expect. The namespace model (global vs per-list vs view-local) must be decided before implementation.

## Capabilities

### New Capabilities
- `timeline-reorder`: Users can reorder tasks via drag in Today, Tomorrow, and Upcoming tabs. Task order persists across app restarts and is consistent with ordering in list detail views.

### Modified Capabilities
- `custom-list-reorder`: Requirement that "Smart segments SHALL NOT support drag-and-drop reordering" is removed. The custom-list-reorder spec is updated to reflect that reordering works everywhere, with a unified mechanism.

## Impact

- `TaskItem.sortOrder` semantics may expand from per-list to global ordering
- `ReminderSegmentViewModel` gains `moveTasks` and potentially `handleDrop` methods
- `ReminderSegmentLogic.sortedTasks` sort key changes
- A shared `SortOrderReordering` utility is extracted from `DetailViewModel.moveTasks`
- `DetailViewModel` is simplified by delegating to the shared utility
- Timeline view templates (TodayView, TomorrowView, UpcomingView via `ReminderSegmentDetailView`) add `.onMove` and drag-drop modifiers
- Existing tests for `DetailViewModel` reorder logic are preserved; new tests for `ReminderSegmentViewModel` reorder + shared utility
