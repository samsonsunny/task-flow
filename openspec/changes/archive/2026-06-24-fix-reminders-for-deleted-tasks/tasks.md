## 1. Filter completed tasks in `reschedulePendingOnLaunch`

- [x] 1.1 Update the `FetchDescriptor` predicate in `NotificationService.reschedulePendingOnLaunch()` to exclude completed tasks (`isCompleted != true`)
- [x] 1.2 Verify the fix: create a completed task with a future due date, relaunch app, confirm no notification is re-scheduled

## 2. Persist deletions immediately

- [x] 2.1 Add `try? modelContext.save()` after `modelContext.delete(task)` in `ListDetailView.swift` (context menu and swipe delete)
- [x] 2.2 Add `try? modelContext.save()` after `modelContext.delete(task)` in `ReminderSegmentDetailView.swift` (context menu and swipe delete)
- [x] 2.3 Add `try? modelContext.save()` after `modelContext.delete(task)` in `CompletedView.swift` (swipe delete)

## 3. Remove delivered notifications on cancel

- [x] 3.1 Add `center.removeDeliveredNotifications(withIdentifiers: [taskId])` to `NotificationService.cancel(taskId:)`
- [x] 3.2 Verify delivered notifications are removed from Notification Center when a task is deleted or completed

## 4. Tests

- [x] 4.1 Run the app and verify: create task with time, complete it → notification does not fire
- [x] 4.2 Run the app and verify: create task with time, delete it → notification does not fire
- [x] 4.3 Run the app and verify: delivered notification is removed from Notification Center on task deletion/completion
- [x] 4.4 Run the app and verify: crashing before auto-save does not result in stale notifications after relaunch
