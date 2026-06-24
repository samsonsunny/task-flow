## Why

When users set a reminder date without enabling the time toggle, the system stores the due date as midnight (00:00) of that day. The app-launch notification rescan then sees this as a future date and schedules a notification for midnight — waking the user up or spamming them with notifications they never asked for. This breaks the user's expectation that "no time toggle = no notification."

## What Changes

- Add a `hasTime` boolean field to the `TaskItem` model to persistently track whether the user explicitly set a time
- Fix `NotificationService.schedule(for:)` to skip scheduling when `hasTime` is false
- Fix `NotificationService.reschedulePendingOnLaunch` to only reschedule tasks with `hasTime == true`
- Fix `CompletedView.uncomplete()` to respect `hasTime` when re-scheduling
- Update all save/update paths (`ReminderDraftMapper.apply`, schedule sheets) to persist `hasTime`
- Add a lightweight schema migration for the new `hasTime` field on `TaskItem`
- No breaking changes to the public API or data model

## Capabilities

### New Capabilities

- `reminder-date-model`: Tracks whether a reminder's date has an explicitly set time. Persists the `hasTime` flag and uses it to gate notification scheduling.

### Modified Capabilities

- `task-notifications`: Requirement for app-launch notification rescan currently scans all tasks with future `dueDate` values. This needs to be narrowed to only reschedule tasks that have an explicitly set time (`hasTime == true`).

## Impact

- **TaskItem model**: New `hasTime` field, schema migration (lightweight)
- **NotificationService**: `schedule(for:)` and `reschedulePendingOnLaunch` need to check `hasTime`
- **ReminderDraftMapper**: Needs to persist `hasTime` on the task
- **ListDetailView / ReminderSegmentDetailView**: Schedule sheet `onCommit` needs to persist `hasTime`
- **ReminderEditorView**: `saveReminder()` logic for notification already checks `draft.hasTime` — no change needed there
- **CompletedView**: `uncomplete()` needs to check `hasTime` before re-scheduling
- **ReminderDraft.init(task:)**: Needs to read `hasTime` from the stored task
