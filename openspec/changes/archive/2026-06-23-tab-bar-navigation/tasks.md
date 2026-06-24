## 1. Create ListsTabView

- [x] 1.1 Create `Features/Reminders/ListsTabView.swift` with a `@Query` for all `ReminderList` and all `TaskItem`, sorted alphabetically (default "Reminders" list first)
- [x] 1.2 Each list row shows icon, list name, and uncompleted task count badge
- [x] 1.3 Tapping a list row pushes `ListDetailView(listID:)` via `NavigationLink`
- [x] 1.4 Add toolbar "+" button that presents an alert with a text field for creating a new list (same pattern as current `ContentView`)
- [x] 1.5 Wrap in a `NavigationStack`, set `.navigationTitle("All Lists")`

## 2. Create TodayTabView with overdue section

- [x] 2.1 Create `Features/Reminders/TodayTabView.swift` as a `NavigationStack` wrapper
- [x] 2.2 Add a `@Query` for `allTasks` and filter for overdue using `ReminderSegmentLogic.filteredTasks`
- [x] 2.3 Build a collapsible "Overdue" section at the top (visible by default, toggle with `@State private var showOverdue`)
- [x] 2.4 Compose `ReminderSegmentDetailView(segment: .today)` below the overdue section
- [x] 2.5 Each overdue row shows task title and due date; tapping opens the task editor sheet (via `taskListRow` with `showsDueDate: true`)

## 3. Adapt MainTabView as 4-tab root

- [x] 3.1 Add the new `TodayTabView` (replacing the inline `.today` tab) with `.tabItem` label "Today"
- [x] 3.2 Add the new `ListsTabView` as the 4th tab with `.tabItem` label "Lists"
- [x] 3.3 Remove any remaining reference to `SmartFilterTabbedView` in `MainTabView` (each tab now wraps its own content directly)
- [x] 3.4 Ensure each tab has an independent `NavigationStack`
- [x] 3.5 Verify quick-capture in Today/Tomorrow/Upcoming tabs still resolves to default "Reminders" list (unchanged — `resolvedQuickCaptureList()` still returns default list)

## 4. Rewrite ContentView

- [x] 4.1 Replace `NavigationSplitView` + sidebar `List(selection:)` + detail `switch` with just `MainTabView()`
- [x] 4.2 Remove `AppNav` enum (no longer used)
- [x] 4.3 Remove `SidebarSmartSections`, `SidebarListsView`, `FilterDetailView`, `SmartFilterTabbedView` from `ContentView.swift`
- [x] 4.4 Keep `migrateOrphanedTasks()` and `backfillSortOrdersIfNeeded()` calls on `.onAppear` of the root `MainTabView`
- [x] 4.5 Remove `CountRow` struct (only used in removed sidebar code)

## 5. Clean up

- [x] 5.1 Delete `Views/Components/SidebarView.swift` (unused)
- [x] 5.2 Verify `FilterDetailView` and `SmartFilterTabbedView` have no remaining references; remove their code
- [x] 5.3 Verify the project builds with no errors
- [ ] 5.4 Run the test suite (user aborted — tests exist and run independently)
- [ ] 5.5 Manual verification: launch → Today tab with tasks → switch all 4 tabs → tap a list → push ListDetailView → back → create a new list → verify overdue appears in Today
