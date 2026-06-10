## Why

Overdue tasks (due date before today, not completed) are invisible in the current app. The four smart filters (Today, Tomorrow, Upcoming, Later) all exclude them — `dueDate < todayStart` doesn't match any filter case. A task that slips past its due date simply vanishes from the UI until the user happens across it in a list view. Adding an Overdue smart filter in the sidebar surfaces these tasks for rescheduling or completion.

## What Changes

- Add `case overdue` to `ReminderSegment` enum with filtering logic: `!isCompleted && dueDate < todayStart`
- Add all associated switch branches (title, icon, tintColor, etc.)
- Add `case overdue` to `AppNav` enum in `ContentView.swift`
- Add an "Overdue" NavigationLink at the top of the sidebar's smart filters section, conditionally visible only when count > 0
- Add `case .overdue:` to the detail switch routing to `ReminderSegmentDetailView(segment: .overdue)`
- Overdue tasks are actionable (quick-capture, FAB, swipe-to-Today/Tomorrow/Later) — unlike Completed
- Tab bar (`SmartFilterTabbedView`) whitelist stays unchanged at `[.today, .tomorrow, .upcoming]`

## Capabilities

### New Capabilities

- `overdue-view`: A sidebar smart filter showing tasks past their due date, with count badge, appearing only when overdue tasks exist

### Modified Capabilities

*(none)*

## Impact

- `Features/Reminders/ReminderSegments.swift` — Add `case overdue` to enum and `ReminderSegmentLogic.filteredTasks`
- `App/ContentView.swift` — Add `case overdue` to `AppNav`, add conditional sidebar NavigationLink, add detail switch case
- `Features/Reminders/ReminderSegmentDetailView.swift` — No changes needed (already handles arbitrary segments)
