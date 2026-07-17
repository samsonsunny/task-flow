## 1. Sort logic — custom order parameter

- [x] 1.1 Add `customOrderIndex: [String: Int]? = nil` parameter to `ReminderSegmentLogic.sortedTasks()` in `TimeSegments.swift`
- [x] 1.2 Implement sort: tasks in custom order sort by index, others fall through to existing date-based sort

## 2. ViewModel — UserDefaults read/write

- [x] 2.1 Add UserDefaults key constants for today/tomorrow/overdue order arrays
- [x] 2.2 Add `readDailyOrder()` / `readDailyOrderArray()` helpers
- [x] 2.3 Pass `customOrderIndex` to `sortedTasks()` in `update()` and `rebuildTree()`
- [x] 2.4 Add `moveTasks(fromOffsets:toOffset:in:orderKey:)` that writes new order to UserDefaults and calls `update()`

## 3. View — wire .onMove

- [x] 3.1 Add `.onMove` to root task `ForEach` via `reorderableFlatContent()` for Today/Tomorrow
- [ ] 3.2 Add `.onMove` to overdue task `ForEach` in the overdue section (deferred — type-checker issue with tuple expressions)
- [x] 3.3 Wire handlers to `viewModel?.moveTasks()`

## 4. Verify

- [x] 4.1 Build and verify no compile errors
- [ ] 4.2 Manual check: Root tasks can be dragged to reorder in Today
- [ ] 4.3 Manual check: Root tasks can be dragged to reorder in Tomorrow
- [ ] 4.4 Manual check: Overdue section has independent ordering
- [ ] 4.5 Manual check: Order persists after app restart
- [ ] 4.6 Manual check: Children follow parent during reorder
- [ ] 4.7 Manual check: New tasks appear at bottom
- [ ] 4.8 Manual check: List view order is unaffected
