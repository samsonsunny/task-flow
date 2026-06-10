## 1. Extract MainTabView

- [x] 1.1 Create `MainTabView` struct in `Features/Reminders/MainTabView.swift` with the current TabView + per-tab NavigationStack logic from `ContentView`
- [x] 1.2 Add `initialTab` parameter to `MainTabView` that sets the initially selected tab
- [x] 1.3 Remove `ReminderRootTab` private enum from `ContentView` and use `ReminderSegment` directly for tab selection
- [x] 1.4 Update each tab's NavigationStack to remove `.navigationDestination(for: ReminderRoute.self)` — it will no longer handle `.segment` or `.list` cases

## 2. Create NavItem and restructure ContentView

- [x] 2.1 Define `NavItem` enum (or equivalent) with `.tabView(initialTab:)` and `.listDetail(id:)` cases
- [x] 2.2 Rewrite `ContentView` to use a single `NavigationStack` with `SidebarView` as root and `path` initialized to `[.tabView(initialTab: .today)]`
- [x] 2.3 Add `.navigationDestination(for: NavItem.self)` to the root NavigationStack routing to `MainTabView` or `ListDetailView`
- [x] 2.4 Remove `selectedTab`, `todayPath`, `tomorrowPath`, `upcomingPath` from `ContentView`
- [x] 2.5 Remove `ZStack`, `TabView`, and `SidebarContainer` overlay from `ContentView`

## 3. Adapt SidebarView for NavigationStack root

- [x] 3.1 Accept a callback or binding for navigation actions instead of writing to `AppState.pendingNavigation`
- [x] 3.2 Remove references to `appState.isSidebarOpen` and `appState.selectedListId`
- [x] 3.3 Update smart filter buttons to call `onSelect(.tabView(initialTab: .today))` etc.
- [x] 3.4 Update list row buttons to call `onSelect(.listDetail(id: list.id))`
- [x] 3.5 Add a guard to prevent pushing a duplicate TabView when the same smart filter is already active

## 4. Trim ReminderSegment

- [x] 4.1 Remove `.scheduled`, `.allReminders`, `.completed`, `.overdue`, `.later` cases from `ReminderSegment`
- [x] 4.2 Remove associated switch branches in `title`, `iconName`, `tintColor`, `showsCount`, `usesGroupedSections`, `includesLaterSection`, `tabTitle`, `subtitle`, `emptyTitle`, `emptyMessage`
- [x] 4.3 Remove unreferenced filtering logic in `ReminderSegmentLogic.filteredTasks()` for removed cases
- [x] 4.4 Update all call sites that reference removed cases (grep for `.scheduled`, `.allReminders`, `.completed`, `.overdue`, `.later`)

## 5. Trim ReminderRoute

- [x] 5.1 Remove `.segment(ReminderSegment)` case from `ReminderRoute`
- [x] 5.2 Remove the Overdue `NavigationLink` in `ReminderSegmentDetailView` that pushed `.segment(.overdue)`

## 6. Clean up AppState

- [x] 6.1 Remove `isSidebarOpen`, `selectedListId`, and `pendingNavigation` from `AppState`
- [x] 6.2 Update all call sites that reference these properties (e.g., `ReminderSegmentDetailView.resolvedQuickCaptureList()`)

## 7. Remove SidebarContainer

- [x] 7.1 Delete `Views/Components/SidebarContainer.swift`
- [x] 7.2 Remove any remaining imports or references to `SidebarContainer`

## 8. Simplify quick-capture

- [x] 8.1 Update `ReminderSegmentDetailView.resolvedQuickCaptureList()` to always return the default "Reminders" list, ignoring any previous list context

## 9. Verify and clean up

- [x] 9.1 Build the project and fix any compilation errors
- [x] 9.2 Build for testing — test compilation succeeds
- [ ] 9.3 Manually verify: launch → TabView shows Today → back-swipe reveals sidebar → tap smart filter pushes TabView → tap list pushes ListDetailView → back-swipe returns to sidebar
- [ ] 9.2 Run the test suite
- [ ] 9.3 Manually verify: launch → TabView shows Today → back-swipe reveals sidebar → tap smart filter pushes TabView → tap list pushes ListDetailView → back-swipe returns to sidebar
