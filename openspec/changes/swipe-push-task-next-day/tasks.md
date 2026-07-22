## 1. ViewModel

- [x] 1.1 Add `rescheduleToNextDay(_ task: TaskItem)` to `ReminderSegmentViewModel` — sets due date to start of next calendar day, cancels existing notification, saves context, and calls `update()` / `BadgeService.update`.
- [x] 1.2 Fix `rescheduleToNextDay` to use task's current due date as base instead of `now`, so Tomorrow view tasks move to day after tomorrow.
- [x] 1.3 Increment `task.deferCount` in `rescheduleToNextDay` on each swipe reschedule.

## 2. Row view

- [x] 2.1 Add optional `onSwipeNextDay: (() -> Void)?` parameter to `TaskRowView`.
- [x] 2.2 When `onSwipeNextDay` is non-nil, add a leading swipe action for reschedule and keep trailing swipe for delete.
- [x] 2.3 Show "Nx deferred" in metadata when `task.deferCount >= 2`.

## 3. Timeline view

- [x] 3.1 In `TimelineView.taskListRow`, when `segment` is `.today` or `.tomorrow`, pass `onSwipeNextDay: { viewModel?.rescheduleToNextDay(task) }`.

## 4. Model

- [x] 4.1 Add `deferCount: Int` property to `TaskItem` in `TaskFlowSchemaV9` with lightweight migration from V8.

## 5. Tests

- [ ] 5.1 Add a test in `ReminderSegmentViewModelTests` verifying that `rescheduleToNextDay` sets the task's due date to the next calendar day start and triggers a model save.
