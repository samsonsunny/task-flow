## Why

The quick capture field is implemented independently in three places (ListDetailView, TimelineView for Today/Tomorrow, TimelineView for Upcoming) with duplicated state management, different field positions, and inconsistent behavior. In List Detail, the field is at the top but new tasks land at the bottom — the user cannot see both in one glance. In Today/Tomorrow, the field is at the top and new tasks float to the top — which works but duplicates the same logic. In Upcoming, the field is per-day at the bottom of sections. Each view manages its own `quickCaptureText`, `skipNextDismiss`, focus state, and commit handler. This is not sustainable.

## What Changes

- Create a **single reusable `QuickCaptureRow`** component in `Views/Components/` that owns its own text, focus, commit, and dismiss behavior
- Move the field position from **top to bottom** (last row inside the `List`) in all views where it currently sits at the top
- On + tap, auto-scroll to the field at the bottom
- New tasks land directly above the field (visible in one glance)
- Upcoming keeps its existing per-day inline capture (unchanged)
- Each view drops from ~30 lines of quick capture boilerplate to ~5

## Capabilities

### New Capabilities

- `quick-capture-field`: Shared inline quick capture component used across ListDetailView and time-based views. Manages its own text, focus, commit, and dismiss state.

### Modified Capabilities

- `list-inline-capture`: Field position moves from top-of-list to last-row. Field behavior changes from parent-managed state to delegated to shared component.
- `task-row-display` (Today/Tomorrow): Quick capture field moves from top to last row position in the task list.

## Impact

- `TaskFlow/Views/Components/QuickCaptureRow.swift` — new shared component
- `TaskFlow/Features/Lists/DetailView.swift` — replace inline quick capture with shared component; revert previous VStack/pinned-bar change; place as last List row
- `TaskFlow/Features/Tasks/Timeline/TimelineView.swift` — replace inline quick capture for Today/Tomorrow with shared component as last List row; Upcoming unchanged
- `TaskFlow/Features/Lists/DetailViewModel.swift` — no changes needed
- `TaskFlow/Features/Tasks/Timeline/TimelineViewModel.swift` — no changes needed
- `openspec/specs/list-inline-capture/spec.md` — update scenarios for new field position
- `openspec/specs/task-row-display/spec.md` — update if Today/Tomorrow capture behavior is documented there
