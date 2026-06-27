## Why

The app icon is currently silent — no badge number appears regardless of how many tasks are overdue or due today. Without a visible pull, users have no reason to open the app between notifications. A badge showing the count of actionable tasks (overdue + today) serves as a persistent call to action, driving the habit of checking and completing tasks.

## What Changes

- Add `.badge` to notification authorization options
- Set `content.badge` on scheduled notifications to keep the badge live even when notifications arrive
- Compute badge number as `overdueTasks.count + todayTasks.count` on every state change (mutation, timer tick, foreground)
- Badge does NOT clear on app open — it stays at the current task count. It only goes to zero when there are zero actionable tasks.
- Persists the last known badge count in `UserDefaults` so it survives app termination

## Capabilities

### New Capabilities
- `task-count-badge`: Show a live badge on the app icon counting overdue + today's tasks

### Modified Capabilities
- `clear-notifications-on-open`: Badge clearing is explicitly excluded from this existing spec (it only clears the notification tray, not the badge)

## Impact

- `NotificationService.swift`: Add `.badge` to auth options, set `content.badge` on scheduled notifications
- `TaskFlowApp.swift` or a shared coordinator: Recompute badge on foreground, mutation, and timer tick
- `ReminderSegmentViewModel` (or new badge service): Compute badge count from existing `filteredTasks` / `overdueTasks`
