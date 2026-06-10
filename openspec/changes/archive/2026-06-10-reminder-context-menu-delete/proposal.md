## Why

Reminders can only be deleted via swipe actions, which are not discoverable on macOS and inconsistent with user expectations on iPad. Adding a Delete option to the context menu provides a consistent, discoverable way to remove reminders across all platforms.

## What Changes

- Add a `Delete` button (destructive role) to the `.contextMenu` in `TaskRowView`
- Add an `onDelete` closure parameter to `TaskRowView`
- Wire `onDelete` to `modelContext.delete(task)` in all views that use `TaskRowView`:
  - `ReminderSegmentDetailView`
  - `ListDetailView`

## Capabilities

### New Capabilities
- `reminder-context-menu-delete`: Adds a delete action to the reminder context menu, accessible via long-press on any reminder row

### Modified Capabilities
<!-- None -->

## Impact

- `TaskRowView.swift` — new `onDelete` parameter + context menu button
- `ReminderSegmentDetailView.swift` — pass `onDelete` to `TaskRowView`
- `ListDetailView.swift` — pass `onDelete` to `TaskRowView`
