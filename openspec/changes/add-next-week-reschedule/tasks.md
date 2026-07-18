## 1. ViewModel Methods

- [x] 1.1 Add `rescheduleToNextWeek(_:)` to `ReminderSegmentViewModel` — compute next Monday, set `dueDate`, cancel notification, save, update
- [x] 1.2 Add `canMoveToNextWeek(_:)` to `ReminderSegmentViewModel` — return false if already due next Monday
- [x] 1.3 Add `rescheduleTaskToNextWeek(_:)` to `ListDetailViewModel` — same logic, calls `recompute` instead of `update`
- [x] 1.4 Add `canMoveToNextWeek(_:)` to `ListDetailViewModel` — same logic

## 2. Context Menu UI

- [x] 2.1 Add `var onMoveToNextWeek: (() -> Void)? = nil` to `TaskRowView`
- [x] 2.2 Add "Next Week" button in `TaskRowView` context menu body (after Tomorrow, before Later)
- [x] 2.3 Pass `onMoveToNextWeek` through in `TaskNodeView`

## 3. Wire Callbacks

- [x] 3.1 Wire `onMoveToNextWeek` in `TimelineView.taskListRow` — call `viewModel?.rescheduleToNextWeek(task)` when `canMoveToNextWeek` is true
- [x] 3.2 Wire `onMoveToNextWeek` in `DetailView` task row — call `viewModel?.rescheduleTaskToNextWeek(task)` when `canMoveToNextWeek` is true

## 4. Verify

- [x] 4.1 Build and confirm no compile errors
- [x] 4.2 Test: long-press a task in Today view, verify "Next Week" appears and sets dueDate to next Monday
- [x] 4.3 Test: long-press a task already due next Monday, verify "Next Week" is hidden
