## 1. ViewModel — Data and grouping

- [x] 1.1 Keep `groupedTasks` with `[(String, [TaskItem])]` for sectioned list display
- [x] 1.2 Sort tasks within each group by completion date descending (newest first)
- [x] 1.3 Add `completionTimeLabel(for:)` static method returning short time for today/yesterday, date for older
- [x] 1.4 Remove `destinationLabel` static method and all callers

## 2. View — Simple list with completion time

- [x] 2.1 Rewrite `CompletedView` as plain grouped List (no timeline lines/dots)
- [x] 2.2 Each row: leading checkmark circle + strikethrough title + trailing completion time
- [x] 2.3 Wire tap-to-uncomplete, swipe-to-delete, and tap-to-edit interactions
- [x] 2.4 Remove destination label display from completed task rows
- [x] 2.5 Delete unused `TimelineRowView` component

## 3. Settings — Navigation entry point

- [x] 3.1 Add "Recently Completed" Section + NavigationLink in the Settings form
- [x] 3.2 Verify navigation title is "Completed" on the pushed view

## 4. Cleanup

- [x] 4.1 Remove unused `destinationLabel` code from `CompletedViewModel`
- [x] 4.2 Verify the app builds and runs with no warnings
- [x] 4.3 Run existing tests and confirm they pass
