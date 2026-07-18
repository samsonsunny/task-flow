## Why

Users need a quick way to defer work tasks to the next workday (Monday) without opening a date picker. The Friday-to-Monday pattern is the most common rescheduling scenario for work tasks, and the current options don't serve it. "Later" removes the date entirely, and "Schedule" requires picking an exact day. Adding "Next Week" gives users a one-tap way to move a task to next Monday, keeping their Today/Tomorrow views clear without losing the task's scheduling intent.

## What Changes

- Add a "Next Week" option to the task context menu, positioned after "Tomorrow" and before "Later"
- "Next Week" sets the task's `dueDate` to the next Monday from today (always lands on Monday)
- The option is hidden if the task is already due next Monday
- Appears consistently in all views (Today, Tomorrow, Upcoming, List detail)

## Capabilities

### New Capabilities
- `next-week-reschedule`: Context menu action that moves a task to the next Monday with a single tap

### Modified Capabilities

## Impact

- `TaskRowView.swift` — new `onMoveToNextWeek` callback + menu item
- `TaskNodeView.swift` — pass through `onMoveToNextWeek` callback
- `TimelineViewModel.swift` — new `rescheduleToNextWeek(_:)` and `canMoveToNextWeek(_:)` methods
- `DetailViewModel.swift` — duplicate the same two methods
- `TimelineView.swift` — wire `onMoveToNextWeek` callback on task row
- `DetailView.swift` — wire `onMoveToNextWeek` callback on task row
