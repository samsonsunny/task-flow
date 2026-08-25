## Why

`ListDetailView` currently renders all tasks flat — subtasks are hidden behind a "2/3" fraction indicator on parent rows. The `task-subtasks` and `task-row-display` specs define hierarchical nesting with indentation, collapse/expand chevrons, and animated transitions, but the implementation passes `nestSubtasks: false` to the tree flattener, explicitly disabling it. Users cannot see or interact with subtasks directly in the list view — they must open the editor to manage them.

## What Changes

- Enable hierarchical nesting in `ListDetailView` by flipping `nestSubtasks: false` → `true`
- Add depth-based leading indentation (20pt per depth level) to task rows in `ListDetailView`
- Add a trailing disclosure chevron to parent task rows (chevron.right when collapsed, chevron.down when expanded)
- Wire chevron tap to `AppState.toggleTaskCollapsed()` with animated transitions
- Persist collapse/expand state across sessions via `UserDefaults` (already implemented in `AppState`)
- Add expanded hit targets (44×44pt) for both completion button and chevron

## Capabilities

### New Capabilities

_(none — all spec requirements already exist)_

### Modified Capabilities

- `task-row-display`: Implementation of existing requirements — chevron control, depth indentation, expanded hit targets. No spec changes needed; the requirements are already defined.
- `task-subtasks`: Implementation of existing "List view displays nested tasks hierarchically" requirement. No spec changes needed.

## Impact

- `DetailViewModel.swift` — flip `nestSubtasks` flag in `recompute()`
- `DetailView.swift` — add `@Environment(AppState.self)`, pass `collapsedTasks` to ViewModel, apply depth-based padding, wire chevron tap
- `TaskRowView.swift` — add trailing chevron UI with expanded hit target, new `isExpanded`/`onToggleExpand` parameters
- `ListDetailViewModelRegressionTests.swift` — update test that asserts flat behavior to assert nested behavior
- No schema migrations, no new dependencies, no API changes
