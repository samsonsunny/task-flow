## Why

Users managing tasks in Today/Tomorrow often need to defer a task by one day quickly. Requiring a long-press, Schedule picker, or context menu adds unnecessary friction for this common triage action.

## What Changes

- Add a right-swipe gesture on task rows in Today and Tomorrow views to reschedule the task to the next day (Today → Tomorrow, Tomorrow → day after tomorrow).
- Overdue tasks in Today are also swipeable right to push them to tomorrow.
- The swipe action uses a full swipe: a single right swipe immediately reschedules the task.
- A light haptic feedback is triggered on successful reschedule.
- The existing trailing swipe delete action is removed from Today/Tomorrow to avoid swipe conflict (delete remains available via context menu).

## Capabilities

### New Capabilities

- `swipe-reschedule`: Right-swipe to reschedule task to the next day in Today and Tomorrow views.

### Modified Capabilities

- `task-row-display`: Update swipe actions configuration to support right-swipe reschedule and remove trailing delete in Today/Tomorrow.

## Impact

- Affected Views: `TaskRowView`, `ReminderSegmentDetailView` (taskListRow), `TodayTabView`, `TomorrowView` (config passed via ReminderSegmentDetailView).
- Affected ViewModels: `ReminderSegmentViewModel` — new method to reschedule task to next day.
- SwiftData model: No changes.
- Affects Today, Tomorrow, and Overdue sections within Today.
