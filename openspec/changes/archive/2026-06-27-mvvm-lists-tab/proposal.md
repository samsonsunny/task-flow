## Why

`ListsTabView` (436 lines) manages list and group CRUD (create, rename, delete, reorder), context menus, delete cascade logic, and group expand/collapse persistence — all inside the view. The alert-based CRUD flows interleave UI state (`@State` for each dialog) with data mutations, making the mutation logic untestable and the view hard to follow across the 6 alert sheets.

## What Changes

- Create `ListsTabViewModel` as an `@Observable` class owning all list/group CRUD logic, delete cascade, reorder, group assignment, and dialog state
- `ListsTabView` becomes a thin consumer: observes VM state, delegates all actions to the VM
- Move to VM: list/group creation, rename, delete with cascade, reorder with midpoint, move-to-group, group expand/collapse persistence, and all alert/sheet presentation state
- View retains only: `@Query` for data, rendering, and NavigationLink structure

## Capabilities

### New Capabilities
- `lists-tab-view-model`: ViewModel for `ListsTabView` owning list/group CRUD, delete cascade, drag-reorder, group assignment, and dialog presentation state

### Modified Capabilities
*None — existing specs are implementation details unaffected by MVVM extraction.*

## Impact

- **New file**: `TaskFlow/Features/Reminders/ViewModels/ListsTabViewModel.swift`
- **Modified**: `ListsTabView.swift` — reduced from ~436 lines to ~200 lines of pure view code
- **All existing specs** remain unchanged — pure refactor with no behavioral changes
