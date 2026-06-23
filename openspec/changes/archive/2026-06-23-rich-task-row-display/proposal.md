## Why

Task row content is needlessly restricted. Titles truncate at 2 lines, notes are hidden entirely from list views, and date/time/list-name metadata is inconsistently displayed depending on the view context. This leaves users scanning more than necessary and forces taps into the editor just to see notes. Making the row information-dense reduces friction and brings the app closer to the glanceability of Apple Reminders.

## What Changes

- Remove the `.lineLimit(2)` constraint on titles in `TaskRowView`, allowing the full title to display with no truncation
- Show notes in `TaskRowView` when the task has notes, hidden when empty
- Add a metadata line below notes showing date, time, and list name contextually:
  - **Time**: shown if the task has a non-midnight time component
  - **Date**: shown if the task has a date AND the view context doesn't already communicate it (omitted in Today, Tomorrow, Upcoming sections)
  - **List name**: shown in segment views (Today, Tomorrow, Overdue, etc.), omitted in `ListDetailView` where it's redundant with the nav title
- Enable date/time display in `ListDetailView` (currently never shown there)
- Apply completed-state styling (secondary color, reduced opacity) uniformly to the entire row including notes and metadata

## Capabilities

### New Capabilities
- `task-row-display`: Defines how task rows render title, notes, and contextual metadata across all list views

### Modified Capabilities
- *None* — existing specs for authoring, completion, etc. have unchanged requirements

## Impact

- `TaskFlow/Views/Components/TaskRowView.swift` — primary change target
- `TaskFlow/Features/Reminders/ListDetailView.swift` — needs `showsDueDate: true` passed to `TaskRowView`
- `TaskFlow/Features/Reminders/ReminderSegmentDetailView.swift` — may need `showsListName: true` if the parameter is added
- No new dependencies, no schema changes, no migration required
