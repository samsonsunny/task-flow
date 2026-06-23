## Why

Tasks with a time set never fire a notification. Users expect a reminder alert at the set time — this is a core expectation of a reminder app. Currently the app shows the time visually but never alerts.

## What Changes

- Schedule a local `UNNotificationRequest` when a task with `hasTime == true` is saved and `dueDate` is in the future
- Request notification authorization on the first save-with-time (not on time toggle)
- Cancel pending notification when task is completed, deleted, or its time is edited
- On app launch, scan all tasks with time set and re-schedule any pending notifications that are missing (handles reinstall)
- Skip scheduling silently when `dueDate` is in the past

## Capabilities

### New Capabilities
- `task-notifications`: Local notification scheduling, cancellation, permission handling, and rescheduling on app launch for tasks with a time set.

### Modified Capabilities
- `reminder-authoring`: Save action gains the side effect of scheduling a local notification when a time is set. This does not change any existing UI or save behavior — the notification is a post-save side effect.

## Impact

- **New file**: `NotificationService.swift` — encapsulates `UNUserNotificationCenter` interactions
- **Modified files**: `ReminderEditorView` or its save handler (trigger scheduling on save), `TaskItem` save/delete/complete paths (trigger cancellation), `TaskFlowApp.swift` (reschedule on launch)
- **Dependencies**: `UserNotifications` framework (built-in, no new package)
