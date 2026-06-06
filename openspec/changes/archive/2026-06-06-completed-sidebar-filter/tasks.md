## 1. Sidebar navigation

- [x] 1.1 Add `case completed` to `AppNav` enum in `ContentView.swift`
- [x] 1.2 Add "Completed" NavigationLink in the sidebar smart filters Section (below Later), with a `checkmark.circle.fill` icon and no count badge
- [x] 1.3 Add `case .completed:` to the detail switch in `NavigationSplitView`, routing to `CompletedView` with `.navigationTitle("Completed")`

## 2. CompletedView

- [x] 2.1 Create `Features/Reminders/CompletedView.swift` with a flat List, querying all tasks and filtering in-memory for `isCompleted == true` within the last 30 days (using `completionDate`)
- [x] 2.2 Implement grouping by completion date into sections: "Today", "Yesterday", "This Week", "Earlier"
- [x] 2.3 Create the task row view with dimmed/strikethrough title, leading checkmark icon, and a subtitle showing the destination segment (derived from `dueDate`: "Overdue", "Today", "Tomorrow", "Upcoming", or "Later")
- [x] 2.4 Implement swipe-to-un-complete: set `isCompleted = false`, clear `completionDate`, removal animation

## 3. Build and verify

- [x] 3.1 Build the project and fix any compilation errors
- [x] 3.2 Run the app and confirm "Completed" appears in sidebar
- [x] 3.3 Complete a task from another view, then navigate to Completed — confirm it appears with correct grouping
- [x] 3.4 Swipe to un-complete in Completed view — confirm task disappears from Completed and reappears in its correct segment
