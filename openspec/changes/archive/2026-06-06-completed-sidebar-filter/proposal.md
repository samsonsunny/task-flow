## Why

Completed tasks are invisible in the current UI — every smart filter and list view excludes them with `guard !isCompleted`. There is no way to un-complete a task that was accidentally marked done, or to review what was recently completed. Adding a "Completed" smart filter in the sidebar gives users a safety net for accidental completions and a way to re-surface tasks back into their original segments.

## What Changes

- Add `case completed` to `AppNav` in `ContentView.swift`
- Add a "Completed" NavigationLink in the sidebar's smart filters section
- Create a `CompletedView` (standalone, not part of `ReminderSegment`/`ReminderSegmentDetailView`)
- The view shows recently completed tasks in a flat list grouped by completion date
- Primary row action: swipe to un-complete (task reappears in its original segment)
- Tab bar (`FilterDetailView`/`SmartFilterTabbedView`) remains unchanged — no "Completed" tab
- No quick-capture, no FAB, no "Move to" actions in this view

## Capabilities

### New Capabilities

- `completed-view`: A sidebar smart filter that lists recently completed tasks with swipe-to-un-complete as the primary interaction

### Modified Capabilities

*(none)*

## Impact

- `App/ContentView.swift` — Add `case completed` to `AppNav` enum, add sidebar NavigationLink, add detail switch case
- New file `Features/Reminders/CompletedView.swift` — Standalone view for completed tasks
- `Models/TaskItem.swift` — Unchanged (existing `isCompleted` and `completionDate` fields are sufficient)
