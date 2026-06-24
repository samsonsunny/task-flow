## 1. Create NotificationService

- [x] 1.1 Create `NotificationService` class wrapping `UNUserNotificationCenter` with `schedule(for task:)`, `cancel(taskId:)`, and `requestAuthorizationIfNeeded()` methods
- [x] 1.2 Implement `schedule` to create `UNNotificationRequest` with `taskId` as identifier and task title as body
- [x] 1.3 Implement `reschedulePendingOnLaunch` to query tasks with future `dueDate` and schedule any missing pending notifications
- [x] 1.4 Add `NotificationService` as an environment object or shared singleton

## 2. Integrate into save flow

- [x] 2.1 After `ReminderEditorView` saves (inserts/updates) a task, call `NotificationService.schedule` when `hasTime == true` and `dueDate > now`
- [x] 2.2 If editing a task that already had a notification, cancel the old one before scheduling the new one

## 3. Integrate into completion toggle

- [x] 3.1 In `ReminderSegmentDetailView.toggleCompletion`, call `NotificationService.cancel` when task is being completed (was incomplete → now complete)
- [x] 3.2 In `ListDetailView.toggleCompletion`, call `NotificationService.cancel` when task is being completed

## 4. Integrate into delete path

- [x] 4.1 In `ReminderSegmentDetailView`, call `NotificationService.cancel` before `modelContext.delete(task)`
- [x] 4.2 In `ListDetailView`, call `NotificationService.cancel` before `modelContext.delete(task)`
- [x] 4.3 In `CompletedView`, call `NotificationService.cancel` before `modelContext.delete(task)` (if applicable)

## 5. Integrate into reschedule operations

- [x] 5.1 In `ReminderSegmentDetailView.rescheduleTaskToToday`, cancel notification (time is stripped)
- [x] 5.2 In `ReminderSegmentDetailView.rescheduleTaskToTomorrow`, cancel notification (time is stripped)
- [x] 5.3 In `ReminderSegmentDetailView.rescheduleTaskToLater`, cancel notification (date cleared)
- [x] 5.4 Repeat for `ListDetailView` equivalents (same methods)

## 6. App launch reschedule

- [x] 6.1 In `TaskFlowApp`, call `NotificationService.reschedulePendingOnLaunch` on the shared model container after app launch
