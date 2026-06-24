## Context

The app has date/time picking fully implemented (via `ReminderDraft.hasTime` and `TaskItem.dueDate`) but no notification infrastructure exists. `UNUserNotificationCenter` is unused. The entitlements file has `aps-environment: development` (unused). No notification-related packages or services exist.

The save flow currently maps `ReminderDraft` → `TaskItem` via `ReminderDraftMapper.apply`. Notifications need to hook into this path and also into completion/deletion/editing paths.

## Goals / Non-Goals

**Goals:**
- Schedule a local notification when a task with time set is saved and `dueDate` is in the future
- Request notification permission automatically on the first save-with-time
- Cancel pending notification on task completion, deletion, or time edit
- Re-schedule any orphaned notifications on app launch
- Encapsulate all `UNUserNotificationCenter` interactions behind a single `NotificationService`

**Non-Goals:**
- Configurable notification timing (always fires at `dueDate`)
- Recurring notifications
- Badge count management
- Remote/push notifications
- In-app notification banner

## Decisions

**1. NotificationService as a stateless facade**
- Wraps `UNUserNotificationCenter` with simple methods: `schedule`, `cancel`, `cancelAll`, `requestAuthorization`, `getPendingRequests`
- No internal state — callers provide the `TaskItem` data needed
- Instantiated as a shared singleton or injected via environment

**2. Permission request on first save-with-time**
- Check `.authorizationStatus` before scheduling
- If `.notDetermined`, request authorization inline, then schedule on grant
- If `.denied`, silently skip (no alert/feedback to user)
- If `.granted`, schedule immediately

**3. Notification identifier uses taskId (UUID string)**
- Enables targeted cancellation on edit/complete/delete
- `UNNotificationRequest` identifier = `taskItem.taskId`
- Content: `title` = task title, `body` = nil (title only), `sound` = `.default`

**4. Hooks in existing paths**

```
Save path (ReminderDraftMapper.apply → modelContext.insert):
  ↓
  hasTime == true && dueDate > now → NotificationService.schedule(task)

Complete path (isCompleted toggle):
  ↓
  NotificationService.cancel(taskId)

Delete path (modelContext.delete):
  ↓
  NotificationService.cancel(taskId)

Edit path (save after editing time):
  ↓
  Cancel old (if any), schedule new (if conditions met)
```

**5. App launch reschedule**
- In `TaskFlowApp.init` or `.onAppear`, query all `TaskItem` where `dueDate > now`
- Get pending notification identifiers via `UNUserNotificationCenter.getPendingNotificationRequests`
- For each task without a matching pending identifier, schedule it
- Avoids double-scheduling and catches reinstall/wiped state

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| User denies permission; notifications silently never fire | User set a time explicitly — their intent is clear. No nagging. They can enable in Settings. |
| App launch reschedule scans all tasks (performance with 1000s of tasks) | SwiftData fetch with `dueDate > now` predicate limits scope. Async dispatch avoids blocking launch. |
| Notification fires while app is in foreground | Default UNNotificationCenter behavior shows banner. If undesirable, implement `userNotificationCenter(_:willPresent:)` delegate to suppress. Non-goal for now — revisit if users complain. |
| taskId is optional (String?) | All tasks created in the current schema have a taskId. Use `guard let id = taskItem.taskId else { return }` — legacy tasks without one silently skip. |
