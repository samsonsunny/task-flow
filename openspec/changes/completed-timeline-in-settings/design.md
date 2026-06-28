## Context

SettingsView currently has no ViewModel and no `@Query`. CompletedView is defined but unreachable from the UI. The existing CompletedViewModel groups completed tasks into buckets (Today/Yesterday/This Week/Earlier) with destination labels. The new design replaces the destination label with a completion-time label, removes the timeline visual in favor of a plain grouped list, and wires the view into Settings via a NavigationLink.

## Goals / Non-Goals

**Goals:**
- Settings gains a "Recently Completed" NavigationLink pushing to CompletedView
- Completed tasks display in a plain grouped list (Today/Yesterday/This Week/Earlier), sorted by completion date descending
- Show completion time (short time for today/yesterday, date for older) on the trailing edge of each row
- Remove destination labels ("Will reappear in...")
- Follow existing MVVM conventions (View holds `@Query`, ViewModel receives data via `update()`)

**Non-Goals:**
- No changes to un-complete, delete, or tap-to-edit interactions
- No changes to the 30-day filter window
- No timeline visual (lines, dots, connecting elements)

## Decisions

### Decision: Simple grouped list, not timeline

Completed tasks display as a standard grouped List with section headers (Today/Yesterday/This Week/Earlier). Within each section, tasks sort by completion date descending. Each row shows: leading checkmark circle, strikethrough title, trailing completion time. This matches Apple's Reminders approach — clean, familiar, no custom drawing.

### Decision: Static `completionTimeLabel` method on ViewModel

A static helper `CompletedViewModel.completionTimeLabel(for:)` formats the completion date. It returns a short time string ("10:30 AM") for today/yesterday tasks, and a date string ("Jun 24") for older tasks. No instance state needed.

### Decision: No SettingsViewModel

SettingsView's existing logic (daily reminder toggle) stays as `@AppStorage`. The completed section is just a NavigationLink. Only the pushed `CompletedView` needs a ViewModel, which it already has.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Existing `CompletedView` test coverage becomes stale | Unit tests on `CompletedViewModel` still work |
| NavigationLink in a Form may look out of place | Use a plain `NavigationLink` in a Section with a `Label` — matches standard Settings patterns |
