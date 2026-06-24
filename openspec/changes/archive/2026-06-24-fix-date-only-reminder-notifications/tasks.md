## 1. Schema & Model Changes

- [x] 1.1 Add `TaskFlowSchemaV5` with `hasTime` (optional `Bool`) on `TaskItem`
- [x] 1.2 Add V4→V5 lightweight migration stage to `TaskFlowMigrationPlan`
- [x] 1.3 Update `typealias` to point to V5 schemas
- [x] 1.4 Add computed property `TaskItem.safeHasTime` with heuristic fallback (nil → check if dueDate time is midnight)
- [x] 1.5 Fix crash: update `ModelContainer` init in `TaskFlowApp.swift` from V4 → V5 (type mismatch caused cast failure at runtime)

## 2. NotificationService Guard

- [x] 2.1 Update `schedule(for:)` to check `safeHasTime` — skip scheduling if `hasTime` is false or nil-with-midnight-time
- [x] 2.2 Update `reschedulePendingOnLaunch` to filter only tasks with `safeHasTime == true`
- [x] 2.3 `cancel(taskId:)` already removes delivered notifications (pre-existing)

## 3. Save Paths — Persist hasTime on Create/Edit

- [x] 3.1 Update `ReminderDraftMapper.apply` to set `task.hasTime = draft.hasTime`
- [x] 3.2 Update `ReminderDraft.init(task:)` to read `task.safeHasTime`
- [x] 3.3 Update `ListDetailView` schedule sheet `onCommit` to set `config.task.hasTime`
- [x] 3.4 Update `ReminderSegmentDetailView` schedule sheet `onCommit` to set `config.task.hasTime`
- [x] 3.5 Verify `ReminderEditorView.saveReminder()` already gates on `draft.hasTime` — confirmed correct
- [x] 4.1 Update `CompletedView.uncomplete()` to gate on `task.safeHasTime`
- [x] 4.2 Verify `saveReminder()` cancels when time toggled off — confirmed correct (line 324-326)

## 5. Verification

- [ ] 5.1 Run the app on simulator and confirm build runs without crash
- [ ] 5.2 Create a reminder with date+time → notification scheduled
- [ ] 5.3 Create a reminder with date only (no time) → no notification
- [ ] 5.4 Edit date-only → enable time → notification scheduled
- [ ] 5.5 Edit time-enabled → disable time → notification cancelled
- [ ] 5.6 Kill app, relaunch → date-only reminders don't get notifications
- [ ] 5.7 Kill app, relaunch → time-enabled reminders get notifications
- [ ] 5.8 Uncomplete a time-enabled reminder → notification rescheduled
- [ ] 5.9 Uncomplete a date-only reminder → no notification
