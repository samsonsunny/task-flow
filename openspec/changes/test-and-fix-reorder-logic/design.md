## Context

The reorder/sort logic uses string-based fractional indexing (`midpoint`/`widen`). The utility functions are well-tested (8 tests), but the ViewModel orchestration methods that use them have zero coverage:

| Method | Tests | Bugs found during exploration |
|--------|-------|-------------------------------|
| `moveTasks(fromOffsets:toOffset:)` | 0 | Widen path uses `first(where:)` on string match → non-deterministic on collision |
| `handleDrop(target:location:)` | 0 | — |
| `moveTaskToRoot()` | 0 | — |
| `moveLists(fromOffsets:toOffset:in:group:)` | 0 | Same widen pattern as `moveTasks` |
| `assignSortOrder(for:in:)` | 0 | — |
| `commitQuickCapture` | 0 | Never assigns sortOrder (nil → collision risk) |
| `isDescendant(_:of:)` | 0 | No cycle detection guard |

## Goals / Non-Goals

**Goals:**
- Write comprehensive tests for all 7 methods listed above using TDD (tests first, code fixes second)
- Fix the `commitQuickCapture` missing sortOrder bug
- Fix the widen path to use positional index instead of string matching
- Remove or safe-guard the `""` fallback dead code
- Add property-based invariant tests (sortOrder uniqueness + monotonicity after any reorder)

**Non-Goals:**
- Changing the midpoint algorithm itself
- Replacing string sortOrder with integers/doubles
- Adding UI tests (drag gesture simulation)
- Testing the Timeline view (no drag-drop reorder there)

## Decisions

### Decision 1: Test structure within existing test file
All tests go into `TaskFlowTests/TaskFlowTests.swift` organized by `// MARK:` sections. No new test file — the existing single-file pattern is established and ViewModel tests need `@MainActor` which works cleanly in one file.

### Decision 2: Test helper for ViewModel setup
Create a `TaskPreviewData`-style helper at the bottom of the test file that sets up a ViewModel with known data:

```
createDetailViewModel(with tasks: [TaskItem], in list: ReminderList, context: ModelContext) -> ListDetailViewModel
```

This avoids duplicating the container/insert/update boilerplate across every test.

### Decision 3: TDD order — most fundamental first
1. `midpoint` edge cases (nil comparison, `widen` under exhaustion)
2. `assignSortOrder` (building block for all other methods)
3. `moveTasks` (core reorder, most complex)
4. `moveLists` (same algorithm, different model)
5. `handleDrop` (builds on sortOrder assignment)
6. `moveTaskToRoot` (depends on root tasks)
7. `isDescendant` (utility for cycle prevention)
8. `commitQuickCapture` (verifies the fix)

### Decision 4: Widen path fix
Replace string-match lookup with positional index:

```
// Before (line 190):
if let upperTask = mutableTasks.first(where: { $0.sortOrder == upperStr })

// After (line 190):
let upperTask = mutableTasks[i + 1]
```

Since widen only fires when `upper` is non-nil (line 188 checks `if let upperStr = upper`), `i + 1` is always a valid index.

### Decision 5: `""` fallback fix
Replace with a safe alternative that extends the lower bound:

```
// Before (line 195):
mutableTasks[i].sortOrder = ""

// After:
let widened = widen(lowerLower)  // widen the lower bound to make room
mutableTasks[i].sortOrder = midpoint(between: widened, and: nil) ?? ""
```

This ensures the fallback produces a value that sorts at the end, not the beginning.

### Decision 6: `commitQuickCapture` fix
Add `assignSortOrder(for: task, in: list)` call before `save()`:

```
// Between lines 128-129:
assignSortOrder(for: task, in: list)
```

### Decision 7: Property-based invariant assertions
Add a helper function `assertValidSortOrder(_:)` that verifies for a given list's tasks:
- No two tasks share the same sortOrder
- sortOrders are in strictly increasing order
- No sortOrder is nil (after the operation)

Call this after every reorder test.

## Risks / Trade-offs

- **Risk: Widen path still causes string growth** → Mitigation: Acceptable, only happens on repeated same-position inserts. A future re-indexing compaction could be added if needed but is unnecessary now.
- **Risk: Tests are slow due to SwiftData container creation** → Mitigation: Use in-memory configuration (`isStoredInMemoryOnly: true`). Container creation per test method (~5ms) is acceptable.
- **Risk: Tests become brittle if sortOrder calculation changes** → Mitigation: Use property-based invariants rather than hardcoded expected sortOrder strings.
