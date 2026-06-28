## Why

Two related bugs:

1. When the app stays in the foreground through midnight, the visible tab shows stale content — tasks remain in "Today" that are now overdue, and the task list doesn't re-filter to match the new day. The 60s timer calls `refreshNow()` but that only updates `overdueTasks`, not the full segment-derived state.

2. A task due at 3:00 PM that's still incomplete at 4:00 PM is shown as "Today" instead of "Overdue". The overdue check only compares `startOfDay`, so time-based overdue tasks are missed until midnight.

## What Changes

- `TimelineViewModel.refreshNow()` delegates to `update(tasks:lists:now:)` instead of only updating `overdueTasks`
- `ListDetailViewModel.refreshNow()` calls `recompute()` instead of just updating `now`
- `ReminderSegmentLogic.filteredTasks` overdue case compares `dueDate < now` for tasks with `hasTime`, and `startOfDay < todayStart` for day-only tasks
- `ReminderSegmentLogic.count` and other callers of `.overdue` segment automatically pick up the new behavior

## Capabilities

### New Capabilities
*(none — fixes to existing logic)*

### Modified Capabilities
- `overdue-view`: The requirement "Overdue view shows past-due tasks" and its scenario "Overdue appears when tasks are overdue" need updating to reflect time-aware comparison

## Impact

- `TimelineViewModel.swift`: 1 line changed in `refreshNow()`
- `ListDetailViewModel.swift`: 1 line changed in `refreshNow()`
- `TimeSegments.swift`: ~5 lines changed in `filteredTasks` overdue case
- No view changes, no model changes
- Sidebar and badge count automatically benefit since they use `ReminderSegmentLogic`
