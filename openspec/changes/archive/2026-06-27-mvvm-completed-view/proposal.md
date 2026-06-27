## Why

`CompletedView` (181 lines) manages recently completed tasks with date-based grouping, un-complete (restore) logic, notification rescheduling, and swipe-to-delete. Though smaller than other views, its mutating operations (un-complete, notification rescheduling) are untestable inline. Extracting a ViewModel keeps the pattern consistent across the codebase and makes these operations testable.

## What Changes

- Create `CompletedViewModel` as an `@Observable` class owning all business logic and presentation state
- `CompletedView` becomes a thin consumer: observes VM state, delegates all actions to the VM
- Move to VM: recent completed task filtering, date-based grouping, un-complete with notification rescheduling, swipe-to-delete
- View retains only: `@Query`, pure-UI state (`editingTask`), and rendering

## Capabilities

### New Capabilities
- `completed-view-model`: ViewModel for `CompletedView` owning completed task filtering, date grouping, un-complete lifecycle, and deletion

### Modified Capabilities
*None.*

## Impact

- **New file**: `TaskFlow/Features/Reminders/ViewModels/CompletedViewModel.swift`
- **Modified**: `CompletedView.swift` — reduced from ~181 lines to ~100 lines of pure view code
