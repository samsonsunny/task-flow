## Why

The task/list reorder system using the string-based midpoint algorithm has zero ViewModel-level test coverage. The `midpoint`/`widen` utility functions are tested in isolation, but the orchestration methods that use them (`moveTasks`, `handleDrop`, `moveLists`, `moveTaskToRoot`, `assignSortOrder`, `isDescendant`) have no tests. During exploration, several real bugs were identified: `commitQuickCapture` never assigns a `sortOrder` (creates nil tasks), the widen path can mutate the wrong task on collision, and the `""` fallback is dead code with dangerous semantics.

A TDD approach — write tests first, fix code to satisfy them — ensures the bugs are caught and the behavior is documented.

## What Changes

- Write comprehensive unit tests for all reorder/sort orchestration methods in `DetailViewModel`, `ListsTabViewModel`, `EditorViewModel`, and `SortOrderMidpoint`
- Fix the `commitQuickCapture` bug (missing `assignSortOrder` call)
- Fix the widen path to use positional indexing instead of string matching
- Fix the `""` fallback or replace with a safe alternative
- Add invariant checks (sortOrder uniqueness + monotonicity) to the test suite

## Capabilities

### New Capabilities
- `reorder-logic-testing`: Test specifications covering all ViewModel-level reorder orchestration, edge cases, and property-based invariants for the string-based midpoint sorting system.

### Modified Capabilities
- (none — this change adds tests and fixes bugs in existing behavior without changing requirements)

## Impact

- **Files tested**: `DetailViewModel.swift`, `ListViewModel.swift`, `EditorViewModel.swift`, `SortOrderMidpoint.swift`, `TimelineViewModel.swift`
- **Files modified**: `DetailViewModel.swift` (fix `commitQuickCapture`, fix widen path), `SortOrderMidpoint.swift` (if the `midpoint` nil edge case is improved)
- **New test targets**: `TaskFlowTests` (new test classes for reorder logic)
- **Test infrastructure**: May need test helpers for setting up ViewModels with SwiftData containers
