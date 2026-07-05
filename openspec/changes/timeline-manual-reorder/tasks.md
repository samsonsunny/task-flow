## 1. Extract shared reorder utility

- [ ] 1.1 Create `SortOrderReordering` enum with a static `reorder(_:fromOffsets:toOffset:)` method in `Utilities/` (mirroring `SortOrderMidpoint.swift` placement)
- [ ] 1.2 Refactor `DetailViewModel.moveTasks(fromOffsets:toOffset:)` to call the shared utility instead of inline logic
- [ ] 1.3 Verify existing `DetailViewModel` reorder tests still pass (no behavioral change)

## 2. Update timeline sort to use sortOrder as primary key

- [ ] 2.1 Modify `ReminderSegmentLogic.sortedTasks` to sort by `sortOrder` (ascending) first, falling back to `dueDate` → `createdAt` → `taskKey` for tasks with `nil` sortOrder
- [ ] 2.2 Verify `ReminderSegmentViewModel.update()` and `rebuildTree()` produce correctly ordered output
- [ ] 2.3 Update `TaskTreeFlattener` if needed (subtrees already sort by sortOrder — no change expected)

## 3. Add drag-reorder to timeline views

- [ ] 3.1 Add `moveTasks(fromOffsets:toOffset:)` method to `ReminderSegmentViewModel` that calls the shared `SortOrderReordering` utility on `sortedFlatTasks`, persists, and calls `update()`
- [ ] 3.2 Add `.onMove` modifier to `ReminderSegmentDetailView`'s `ForEach` over flat nodes, wired to the ViewModel's `moveTasks`
- [ ] 3.3 Ensure drag affordance appears (verify implicit `.onMove` behavior on List/ForEach)

## 4. Update quick capture sortOrder assignment

- [ ] 4.1 Modify `ReminderSegmentViewModel.assignSortOrder(for:in:)` (or create an overload) that places new tasks after the last visible task in the current view, not just the last task in its list
- [ ] 4.2 Verify quick-captured task appears at bottom of the timeline view

## 5. Write tests

- [ ] 5.1 Unit tests for shared `SortOrderReordering.reorder()` — basic reorder, multi-task reorder, midpoint exhaustion/widen
- [ ] 5.2 Unit tests for `ReminderSegmentViewModel.moveTasks` — verify reorder within a segment, cross-list reorder, persistence
- [ ] 5.3 Unit tests for updated `ReminderSegmentLogic.sortedTasks` — sortOrder primary, fallback order, nil sortOrder placement
- [ ] 5.4 Regression tests — existing `DetailViewModel` reorder behavior unchanged after refactor

## 6. Clean up

- [ ] 6.1 Remove "Smart segments show no reorder affordance" test from test suite (if it exists)
- [ ] 6.2 Verify no dead code remains in `DetailViewModel` after extraction
