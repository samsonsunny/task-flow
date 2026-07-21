## 1. ViewModel

- [x] 1.1 Add `rescheduleToNextDay(_ task: TaskItem)` to `ReminderSegmentViewModel` — sets due date to start of next calendar day, cancels existing notification, saves context, and calls `update()` / `BadgeService.update`.

## 2. Row view

- [x] 2.1 Add optional `onSwipeNextDay: (() -> Void)?` parameter to `TaskRowView`.
- [x] 2.2 When `onSwipeNextDay` is non-nil, replace the existing trailing `.swipeActions` with a non-destructive trailing swipe that calls `onSwipeNextDay`, configured with `allowsFullSwipe: true`.

## 3. Timeline view

- [x] 3.1 In `ReminderSegmentDetailView.taskListRow`, when `segment` is `.today` or `.tomorrow`, pass `onSwipeNextDay: { viewModel?.rescheduleToNextDay(task) }` and omit the existing destructive delete swipe action. For other segments, keep current behaviour.

## 4. Tests

- [ ] 4.1 Add a test in `ReminderSegmentViewModelTests` verifying that `rescheduleToNextDay` sets the task's due date to the next calendar day start and triggers a model save.
