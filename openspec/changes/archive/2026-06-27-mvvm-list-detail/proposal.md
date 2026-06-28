## Why

`ListDetailView` is 526 lines, mixing `@Query` data fetching, business logic (drag-drop reorder, nesting, quick capture, completion, scheduling), UI state, and rendering in a single file. This makes business logic untestable in isolation and the view hard to reason about. Extracting a ViewModel separates concerns and enables unit testing of task operations without view lifecycle.

## What Changes

- Create `ListDetailViewModel` as an `@Observable` class owning all business logic and presentation state for the list detail screen
- `ListDetailView` becomes a thin consumer: observes VM state, delegates all mutations to the VM
- Move to VM: task queries (via `modelContext`), flat node building, drag-drop reorder, completion toggling, quick capture, scheduling, collapse state, and swipe-to-delete
- View retains only: `@Query` for fetching data (passed into VM), pure-UI state (edit mode, focus), and rendering

## Capabilities

### New Capabilities
- `list-detail-view-model`: ViewModel for `ListDetailView` owning task list management, drag-drop reorder, nested task hierarchy, quick capture, completion lifecycle, scheduling, and deletion

### Modified Capabilities
*None — existing specs are implementation details unaffected by MVVM extraction.*

## Impact

- **New file**: `TaskFlow/Features/Reminders/ViewModels/ListDetailViewModel.swift`
- **Modified**: `ListDetailView.swift` — gutted from ~526 lines to ~200 lines of pure view code
- **All existing specs** remain unchanged — this is a pure refactor with no behavioral changes
