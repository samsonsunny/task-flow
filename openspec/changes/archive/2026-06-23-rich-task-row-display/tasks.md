## 1. Restructure TaskRowView layout

- [x] 1.1 Remove `.lineLimit(2)` from title `Text` — no replacement limit, title grows freely
- [x] 1.2 Add `showsListName: Bool = true` parameter to `TaskRowView`
- [x] 1.3 Add notes view below title: `Text(task.safeDescription)` at `system(size: 14, weight: .regular)` with `textSecondary` color, conditionally rendered only when `!task.safeDescription.isEmpty`
- [x] 1.4 Replace the existing date/time conditional subtitle block with a single combined metadata line that builds an array of components (time, date, list name), joins them with ` · `, and renders only when non-empty
- [x] 1.5 Apply completed-state styling (textSecondary color, 0.82 opacity) to both the notes view and the metadata line, matching the title's existing treatment

## 2. Update callers

- [x] 2.1 In `ListDetailView.swift`, pass `showsDueDate: true` to `TaskRowView` to enable date/time in list detail context
- [x] 2.2 In `ListDetailView.swift`, pass `showsListName: false` to `TaskRowView` since the list name is already the nav title
- [x] 2.3 Verify `ReminderSegmentDetailView.swift` callers use default `showsListName: true` — no change needed if the parameter has a default value

## 3. Verify

- [x] 3.1 Build the project and fix any compile errors
- [ ] 3.2 Run the app and visually verify rows in Today, Tomorrow, Upcoming, Later, Overdue, and a custom list — confirm titles wrap, notes appear when present, metadata line shows correct components per context
