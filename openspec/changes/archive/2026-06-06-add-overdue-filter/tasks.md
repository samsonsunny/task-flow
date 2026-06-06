## 1. ReminderSegment enum

- [x] 1.1 Add `case overdue` to `ReminderSegment` enum
- [x] 1.2 Add switch branches for `title` ("Overdue"), `iconName` ("exclamationmark.circle.fill"), `tintColor` (red/destructive), `usesGroupedSections` (false), `subtitle` (nil), `emptyTitle`, `emptyMessage`
- [x] 1.3 Add `case .overdue:` to `ReminderSegmentLogic.filteredTasks`: `guard !isCompleted, let dueStart else { return false }; return dueStart < todayStart`

## 2. Sidebar navigation

- [x] 2.1 Add `case overdue` to `AppNav` enum in `ContentView.swift`
- [x] 2.2 Add conditional NavigationLink for Overdue at the top of the smart filters Section, before Today, wrapped in `if ReminderSegmentLogic.count(for: .overdue, tasks: allTasks) > 0`, with a red-tinted `exclamationmark.circle.fill` icon and count badge
- [x] 2.3 Add `case .overdue:` to the detail switch in `NavigationSplitView`, routing to `ReminderSegmentDetailView(segment: .overdue)` with `.navigationTitle("Overdue")`

## 3. Build and verify

- [x] 3.1 Build the project and fix any compilation errors
- [ ] 3.2 Run the app and confirm Overdue appears when a task is past due
- [ ] 3.3 Complete or reschedule the last overdue task — confirm Overdue disappears from sidebar
- [ ] 3.4 Confirm all row interactions work (complete, swipe to Today/Tomorrow/Later, delete)
