## Context

The `SmartFilterTabbedView` in `ContentView.swift` builds its tab bar by iterating `ReminderSegment.allCases`, which includes `.later`. This causes a 4th "Later" tab to appear even though the sidebar already has a dedicated "Later" navigation link.

The existing `sidebar-navigation` spec previously called for removing `.later` from the `ReminderSegment` enum entirely, but that approach is more invasive than needed — `.later` remains useful for sidebar navigation and task filtering logic. The simpler fix is to use an explicit segment whitelist at the tab bar construction site.

## Goals / Non-Goals

**Goals:**
- Remove "Later" as a 4th tab in `SmartFilterTabbedView`
- Keep `.later` in the `ReminderSegment` enum for sidebar and filtering use
- Keep the sidebar "Later" navigation link unchanged

**Non-Goals:**
- Not changing `ReminderSegment` enum definition
- Not changing `ReminderSegmentLogic` filtering
- Not changing sidebar layout or `ContentView` `NavigationSplitView` structure
- Not changing any other tab bar behavior, quick-capture, or task editing

## Decisions

### Decision 1: Explicit whitelist over filtering allCases

**Chosen:** Replace the body of the `ForEach` in `SmartFilterTabbedView` to iterate an explicit array literal `[.today, .tomorrow, .upcoming]` instead of `ReminderSegment.allCases`.

**Alternatives considered:**
- `ReminderSegment.allCases.filter { $0 != .later }`: Works but ties the exclusion to a specific case name. If more cases are added in the future, this filter may need updating. Less explicit about what the tab bar is meant to show.
- Adding a computed property `static var tabCases: [ReminderSegment]` to the enum: Clean separation, but adds API surface to the enum for a single call site. Over-engineered for a one-line change.
- Removing `.later` from the enum entirely: Too invasive — `.later` is used in the sidebar, filtering logic, swipe actions, etc. Unnecessary churn.

### Decision 2: Inline whitelist in the existing code

**Chosen:** Change only the array source in the existing `ForEach` loop at `ContentView.swift:199`. No new views, no restructuring.

**Rationale:** Minimal diff, single point of change, trivially reviewable. The whitelist lives right where the tabs are defined, making the intent obvious.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| If a future developer adds a new `ReminderSegment` case expecting it to auto-appear in the tab bar, it won't | The explicit whitelist makes this obvious — adding a tab is a conscious decision in `SmartFilterTabbedView`. This is a feature, not a bug. |
