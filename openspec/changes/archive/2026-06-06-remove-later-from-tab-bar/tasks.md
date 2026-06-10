## 1. Tab bar whitelist

- [x] 1.1 In `App/ContentView.swift`, replace `ReminderSegment.allCases` with `[ReminderSegment.today, .tomorrow, .upcoming]` in `SmartFilterTabbedView`'s `ForEach`
- [x] 1.2 Build the project and verify compilation succeeds

## 2. Verify

- [x] 2.1 Run the app and confirm the tab bar shows only Today, Tomorrow, Upcoming tabs
- [x] 2.2 Confirm the sidebar "Later" link still works and shows tasks with no due date
- [x] 2.3 Confirm swipe-to-Later on task rows still works
