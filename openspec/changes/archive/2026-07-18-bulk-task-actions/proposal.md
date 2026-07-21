## Why

TaskFlow currently requires performing actions on tasks one at a time — rescheduling, moving to lists, changing priority, or deleting. For users with many tasks, this creates friction when reorganizing their day. Apple's native apps (Reminders, Notes, Mail) all support multi-select with bulk actions via a consistent pattern: ⋯ menu → "Select Items" → bottom toolbar with batch operations. TaskFlow should match this expectation.

## What Changes

- Add a selection mode to all task list screens (Today, Tomorrow, Upcoming, Later/ListDetailView, Completed)
- Entry point: "Select Items" in the ⋯ (ellipsis) toolbar menu on all screens
- ListDetailView and CompletedView gain a ⋯ toolbar button (currently missing)
- In selection mode: completion circles are replaced by selection circles, rows get a subtle tint on selection, a bottom toolbar appears with bulk actions, and "Done" replaces ⋯ in the navigation bar
- Bottom toolbar actions: Date (reschedule), Move (to list), Tag/Priority, Complete/Incomplete, Delete (with confirmation)
- Selection state: independent per row including subtasks; all subtasks auto-expand on enter, collapse state restored on exit
- Selection mode disables: context menus, swipe actions, FAB, tap-to-edit (tap toggles selection instead)

## Capabilities

### New Capabilities
- `bulk-selection`: Selection mode UI — entering/exiting, selection circles replacing completion circles, row tinting, collapse/expand behavior, bottom toolbar with count indicator
- `bulk-operations`: Batch execution of actions on selected tasks — reschedule, move to list, set priority, add tag, complete/incomplete, delete with confirmation

### Modified Capabilities

## Impact

- **Views modified**: `TaskRowView` (selection circle mode), `ReminderSegmentDetailView`/`TimelineView` (selection state + bottom toolbar), `ListDetailView` (add ⋯ toolbar + selection), `CompletedView` (add ⋯ toolbar + selection), `TodayView`/`TomorrowView`/`UpcomingView` (⋯ becomes Menu)
- **ViewModels modified**: `ReminderSegmentViewModel` (bulk operation methods), `ListDetailViewModel` (bulk operation methods), `CompletedViewModel` (bulk operation methods)
- **New files**: Bottom toolbar component, selection state management
- **No API/data model changes**: All operations use existing ViewModel methods in a loop
