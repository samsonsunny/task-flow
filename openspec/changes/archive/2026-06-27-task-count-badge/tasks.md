## 1. Badge Computation

- [x] 1.1 Add `badgeCount(tasks:now:)` static method to `ReminderSegmentLogic`
- [x] 1.2 Create `BadgeService` (or integrate into `NotificationService`) with an `update()` method that computes badge from all tasks and sets `UIApplication.shared.applicationIconBadgeNumber`

## 2. Notification Authorization & Content

- [x] 2.1 Add `.badge` to `requestAuthorization` options array
- [x] 2.2 Set `content.badge` with current badge count in `NotificationService.schedule(for:)`
- [x] 2.3 Set `content.badge` in `scheduleDailyReminder`

## 3. Trigger Points

- [x] 3.1 Call badge update after task completion in `ReminderSegmentViewModel.toggleCompletion`
- [x] 3.2 Call badge update after task creation in `commitQuickCapture` and `EditorViewModel`
- [x] 3.3 Call badge update after task deletion in `delete(task:)` (both ViewModels)
- [x] 3.4 Call badge update after reschedule in `scheduleTask`, `rescheduleToToday`, `rescheduleToTomorrow`, `rescheduleToLater`
- [x] 3.5 Call badge update on foreground in `TaskFlowApp` (scenePhase.active)

## 4. Verify

- [x] 4.1 Build the project with `xcodebuild`
- [x] 4.2 Confirm badge appears with correct count (manual: have 3 overdue tasks + 2 today tasks, badge shows 5)
