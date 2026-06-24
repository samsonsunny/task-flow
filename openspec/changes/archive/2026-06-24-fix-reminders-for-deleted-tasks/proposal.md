## Why

Reminders (local notifications) fire for tasks that are completed or deleted, causing user confusion. The app re-schedules notifications for these inactive tasks on every launch, and already-delivered notifications are never cleaned up when a task is deleted.

## What Changes

- Filter out completed tasks in `reschedulePendingOnLaunch` so notifications are never re-scheduled for them
- Add `try? modelContext.save()` after every `modelContext.delete(task)` call so deletions are persisted immediately
- Extend `cancel()` to also remove already-delivered notifications from Notification Center
- (Optional) Make `taskId` non-optional for robustness

## Capabilities

### New Capabilities

*none*

### Modified Capabilities

- `task-notifications`: Add requirements that (1) notifications are never re-scheduled for completed or deleted tasks on app launch, (2) cancellation removes both pending and delivered notifications, (3) task deletions are persisted immediately to prevent stale notification re-scheduling

## Impact

- `NotificationService.swift` — update `cancel()` and `reschedulePendingOnLaunch()` logic
- `ListDetailView.swift`, `ReminderSegmentDetailView.swift`, `CompletedView.swift` — add `try? modelContext.save()` after each delete
- `TaskItem.swift` — optional: make `taskId` non-optional
