## Context

SettingsView currently has no ViewModel and no `@Query`. CompletedView is defined but unreachable from the UI. The existing CompletedViewModel groups completed tasks into buckets (Today/Yesterday/This Week/Earlier) with destination labels. The new design replaces the grouped list with a visual timeline, removes destination labels, and wires the view into Settings via a NavigationLink.

## Goals / Non-Goals

**Goals:**
- Settings gains a "Recently Completed" NavigationLink pushing to a timeline view
- Completed tasks display chronologically by completion date with visual timeline lines/dots
- Remove destination labels ("Will reappear in...")
- Update CompletedViewModel to supply timeline-position metadata for view rendering
- Follow existing MVVM conventions (View holds `@Query`, ViewModel receives data via `update()`)

**Non-Goals:**
- No changes to un-complete, delete, or tap-to-edit interactions
- No changes to the 30-day filter window
- No new capabilities beyond the completed timeline

## Decisions

### Decision: Timeline position model in ViewModel

A `CompletedTimelineItem` wrapper lets the view draw lines/dots without layout logic in the ViewModel.

```
CompletedTimelineItem
├── id: String
├── task: TaskItem
├── completionTime: Date
├── timeString: String          // "10:30 AM" or "Yesterday"
├── position: TimelinePosition   // first, middle, last, single
└── groupTitle: String          // "Today", "Yesterday", etc.
```

The ViewModel exposes `timelineGroups: [CompletedTimelineGroup]` where each group has a title + date + items. Position is computed by the ViewModel during `update()`.

### Decision: Timeline line drawn in view layer

The vertical line and dots are drawn using SwiftUI `Path` in a `ZStack` overlay on each row. A custom `TimelineRowView` wraps the existing `TaskRowView` in the timeline container. This keeps the line-drawing purely visual and reusable.

```
TimelineRowView
┌────┬────────────────────────┐
│    │  10:30                 │
│ ●──┤  Buy groceries         │
│    │                        │
│ ●──┤  09:15                 │
│    │  Call dentist          │
│ ●──┤                        │
└────┴────────────────────────┘
```

### Decision: SettingsView gets `@Query` directly

Per MVVM conventions, the View holds `@Query`. SettingsView adds a `@Query` and passes `allTasks` to the pushed `CompletedView`. The `CompletedView` already has its own `@Query` — the Settings NavigationLink's destination instantiates it fresh, so no data passing needed.

Alternatively, the `CompletedView` keeps its existing `@Query`. Settings just adds a NavigationLink pointing to it. This is the simplest approach and matches the existing pattern.

### Decision: No SettingsViewModel

SettingsView's existing logic (daily reminder toggle) stays as `@AppStorage`. The completed section is just a NavigationLink. Only the pushed `CompletedView` needs a ViewModel, which it already has.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Timeline lines may break with dynamic type / accessibility sizes | Use `GeometryReader` sparingly; prefer `.overlay` with relative positioning |
| Existing `CompletedView` test coverage becomes stale | Unit tests on `CompletedViewModel` still work; update for new data types |
| NavigationLink in a Form may look out of place | Use a plain `NavigationLink` in a Section with a `Label` — matches standard Settings patterns |
