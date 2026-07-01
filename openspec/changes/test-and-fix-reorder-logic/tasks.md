## 1. Test Infrastructure

- [x] 1.1 Add `createDetailViewModel` test helper that sets up an in-memory container, creates a list, inserts tasks with known sortOrders, and returns a configured `ListDetailViewModel`
- [x] 1.2 Add `createListsTabViewModel` test helper for list reorder tests
- [x] 1.3 Add `assertValidSortOrders` helper that verifies sortOrder uniqueness + monotonicity across all test scenarios
- [x] 1.4 Add `makeTasks` convenience function for creating arrays of TaskItem with specified sortOrders

## 2. Midpoint Utility Edge Case Tests

- [x] 2.1 Write test: `midpoint(nil, "")` produces valid result (nil lower with empty string upper)
- [x] 2.2 Write test: `midpoint("a", nil)` produces valid result sorting after "a"
- [x] 2.3 Write test: exhaustion chain — insert between same bounds until widen fires, verify order preserved
- [x] 2.4 Write test: `midpoint` returns nil for truly impossible gap, verify recovery path is triggered

## 3. assignSortOrder Tests

- [x] 3.1 Write test: assignSortOrder places task at end of existing list
- [x] 3.2 Write test: assignSortOrder places task correctly in single-item list
- [x] 3.3 Write test: assignSortOrder works for first task in empty list (produces non-nil sortOrder)

## 4. moveTasks — Tests + Code Fix

- [x] 4.1 Write test: move first task to last position preserves order invariants
- [x] 4.2 Write test: move last task to first position preserves order invariants
- [x] 4.3 Write test: move task to same index is a no-op (sortOrders unchanged)
- [x] 4.4 Write test: move multiple non-adjacent items (fromOffsets [0,2]) preserves relative order
- [x] 4.5 Write test: move adjacent items (fromOffsets [2,3]) doesn't crash
- [x] 4.6 Write test: midpoint exhaustion triggers widen path without crashing or corrupting order
- [x] 4.7 **Fix widen path**: Replace `first(where: { $0.sortOrder == upperStr })` with positional index `mutableTasks[i + 1]`
- [x] 4.8 **Fix `""` fallback**: Replace empty string with safe alternative that extends lower bound

## 5. handleDrop — Tests

- [x] 5.1 Write test: drop on upper zone (y < threshold) reorders dragged task before target among siblings
- [x] 5.2 Write test: drop on lower zone (y >= threshold) makes dragged task a child of target
- [x] 5.3 Write test: drop task on itself is a no-op
- [x] 5.4 Write test: drop parent onto descendant is rejected (cycle prevention)
- [x] 5.5 Write test: drop into task with existing subtasks appends at end
- [x] 5.6 Write test: drop into task with no subtasks creates first child

## 6. moveTaskToRoot — Tests

- [x] 6.1 Write test: un-nest task to empty root assigns valid sortOrder
- [x] 6.2 Write test: un-nest task to root with existing siblings places at end

## 7. moveLists — Tests

- [x] 7.1 Write test: move list within same group preserves group assignment
- [x] 7.2 Write test: move list to different group reassigns group correctly
- [x] 7.3 Write test: move list to empty group creates single entry

## 8. isDescendant — Tests

- [x] 8.1 Write test: direct parent returns true
- [x] 8.2 Write test: grandparent (depth 2) returns true
- [x] 8.3 Write test: unrelated task returns false
- [x] 8.4 Write test: self returns false

## 9. commitQuickCapture — Fix + Test

- [x] 9.1 **Fix `commitQuickCapture`**: Add `assignSortOrder(for: task, in: list)` call before save
- [x] 9.2 Write test: quick-captured task in non-empty list gets non-nil sortOrder at end
- [x] 9.3 Write test: quick-captured task in empty list gets non-nil sortOrder

## 10. Property-Based Invariant Tests

- [x] 10.1 Write test: chain N reorder operations at the same position, verify invariants after each
- [x] 10.2 Write test: cross-list move followed by reorder within new list preserves all invariants

## 11. Final Verification

- [ ] 11.1 Run full test suite and confirm all tests pass (including existing midpoint tests)
- [ ] 11.2 Verify no existing behavior regressed by code fixes
