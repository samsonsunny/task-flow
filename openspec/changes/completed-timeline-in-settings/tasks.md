## 1. ViewModel — Timeline data structures

- [ ] 1.1 Add `CompletedTimelineItem` and `CompletedTimelineGroup` structs to `CompletedViewModel`
- [ ] 1.2 Add `timelineGroups` published property replacing `groupedTasks`
- [ ] 1.3 Implement timeline position computation in `update()` (first/middle/last/single per group)
- [ ] 1.4 Add completion-time formatting helper (short time string for today/yesterday, date for older)
- [ ] 1.5 Remove `destinationLabel` static method and all callers

## 2. View — Timeline rendering

- [ ] 2.1 Create `TimelineRowView` component wrapping a task row with vertical line + dot + time axis
- [ ] 2.2 Rewrite `CompletedView` body to iterate `timelineGroups` and render `TimelineRowView` per item
- [ ] 2.3 Implement vertical line drawing using `Path` overlay, with proper end caps per group
- [ ] 2.4 Wire tap-to-uncomplete, swipe-to-delete, and tap-to-edit on timeline rows
- [ ] 2.5 Remove destination label display from completed task rows

## 3. Settings — Navigation entry point

- [ ] 3.1 Add `@Query` to `SettingsView` for `allTasks` (if needed for previewing count, or just add NavigationLink)
- [ ] 3.2 Add "Recently Completed" Section + NavigationLink in the Settings form
- [ ] 3.3 Verify navigation title is "Completed" on the pushed view

## 4. Cleanup

- [ ] 4.1 Remove unused `groupedTasks` and `destinationLabel` code from `CompletedViewModel`
- [ ] 4.2 Verify the app builds and runs with no warnings
- [ ] 4.3 Run existing tests and confirm they pass
