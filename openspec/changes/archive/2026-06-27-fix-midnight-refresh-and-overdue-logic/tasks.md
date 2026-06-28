## 1. Fix Midnight Refresh

- [x] 1.1 Change `TimelineViewModel.refreshNow()` to call `update(tasks:allTasks, lists:lists, now: Date())`
- [x] 1.2 Change `ListDetailViewModel.refreshNow()` to update `now` and call `recompute()`

## 2. Fix Time-Aware Overdue Logic

- [x] 2.1 Update `ReminderSegmentLogic.filteredTasks` overdue case to compare `dueDate < now` for `hasTime` tasks

## 3. Sync Spec

- [x] 3.1 Sync modified `overdue-view` spec to main specs

## 4. Verify

- [x] 4.1 Build with `xcodebuild`
