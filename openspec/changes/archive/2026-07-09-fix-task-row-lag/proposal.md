## Why

Task list views (Today, Tomorrow, Later, List Detail) exhibit noticeable lag when scrolling and interacting. The root cause is that `TaskRowView` re-renders its entire body on every parent state change — including an expensive `NSDataDetector` scan — because it lacks `Equatable` conformance to let SwiftUI skip no-op updates. Secondary causes include redundant data fetching and unnecessary array allocations per row.

## What Changes

- Cache the `NSDataDetector` in a `static let` on `TaskRowView` so link detection regex is compiled once, not per-render
- Add `Equatable` conformance to `TaskRowView` so SwiftUI skips re-renders when row inputs haven't changed
- Stabilize `listSections` by storing it in the ViewModel instead of recomputing it as a computed property for every row
- Scope the `@Query` in `ListDetailView` to fetch only tasks belonging to the current list, not all tasks in the database
- Guard the cascading `onChange` handlers in `ReminderSegmentDetailView` against no-op updates by comparing before calling `update()`

## Capabilities

### New Capabilities

- `task-row-performance`: Performance optimization of TaskRowView — Equatable conformance, cached NSDataDetector, and stable view inputs to eliminate unnecessary re-renders

### Modified Capabilities

- `task-row-display`: Add performance-oriented requirements (Equatable conformance, cached link detection) to the existing display spec

## Impact

- `TaskRowView.swift` — static cache + Equatable conformance
- `TimelineView.swift` — guard onChange handlers, store listSections in ViewModel
- `DetailView.swift` — scope @Query to list-specific tasks
- `TimelineViewModel.swift` — expose listSections as stored property
- `DetailViewModel.swift` — expose listSections as stored property
