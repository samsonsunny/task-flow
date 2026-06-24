## Context

When a task is deleted or completed, its local notification should never fire again. Currently:

1. `NotificationService.reschedulePendingOnLaunch()` fetches all tasks with a non-nil `dueDate` — including completed tasks — and re-schedules notifications for them on every launch.
2. `modelContext.delete(task)` is not followed by `modelContext.save()`, so a crash before auto-save leaves the task in the store. On relaunch, the "deleted" task gets a notification re-scheduled.
3. `cancel()` only removes pending notifications via `removePendingNotificationRequests`, but never removes already-delivered ones via `removeDeliveredNotifications`. If a notification fired before the user deleted/completed the task, it stays in Notification Center.

The changes are small and contained — no new dependencies, no architectural changes.

## Goals / Non-Goals

**Goals:**
- No notifications fire for completed or deleted tasks
- Delivered notifications are cleaned up when their task is deleted/completed
- Task deletions survive app termination

**Non-Goals:**
- Changing the notification scheduling architecture (UNNotificationRequest pattern stays)
- Adding a server-side component
- UI changes

## Decisions

### Decision 1: Filter `isCompleted` in `reschedulePendingOnLaunch`

| Option | Approach | Verdict |
|---|---|---|
| Filter in fetch predicate | Add `&& isCompleted != true` to `FetchDescriptor` predicate | ✅ Adopted |
| Clear `dueDate` on completion | Set `task.dueDate = nil` when completing | Rejected: loses date info needed for "un-complete" feature |
| Filter in memory after fetch | `.filter { !$0.isCompleted }` after fetch | Rejected: predicate is cleaner and more efficient |

**Rationale:** The fetch predicate is the right level — the database never returns completed tasks, so no work is wasted. Clearing `dueDate` on completion would prevent restoring it if the user un-completes a task.

### Decision 2: Explicit `try? modelContext.save()` after delete

**Rationale:** SwiftData auto-save is asynchronous and not guaranteed before app termination. An explicit synchronous save after every delete ensures the delete is durable. The save is wrapped in `try?` to swallow errors — the notification system is best-effort and a failed save should not block the UI.

### Decision 3: Add `removeDeliveredNotifications` to `cancel()`

**Rationale:** `removePendingNotificationRequests` only affects future notifications. Adding `removeDeliveredNotifications` ensures the badge/notification in Notification Center is also cleaned up. Both calls use the same `taskId` identifier.

## Risks / Trade-offs

- **[Low] `try? modelContext.save()` on the main thread** — each delete adds a synchronous disk write. For the single-task delete case this is negligible. If batch delete is added later, consider `modelContext.save()` in a background context.
- **[Low] Completed tasks with future due dates** — `reschedulePendingOnLaunch` will skip them, but the `dueDate` field is still populated. The UI still shows dates on completed tasks, which is the existing behavior. This is intentional.
- **[Low] `taskId` could be nil** — if `task.taskId` is nil on an existing task in the store, notification cancellation is silently skipped. This is pre-existing and out of scope for this change.
