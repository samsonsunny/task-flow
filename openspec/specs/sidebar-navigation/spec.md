## ADDED Requirements

### Requirement: NavigationStack root with sidebar

The app SHALL use a single `NavigationStack` as the root container. The sidebar (`SidebarView`) SHALL be the root view of this stack. On launch, the stack path SHALL be pre-populated with `[.tabView(initialTab: .today)]` so the user lands on the TabView immediately without seeing the sidebar.

The sidebar SHALL be revealed when the user swipes back from the left edge of the TabView, using the standard iOS back-swipe gesture.

#### Scenario: App launches to TabView, not sidebar
- **WHEN** the app launches
- **THEN** the user sees the TabView with Today tab selected, not the sidebar
- **AND** the sidebar is reachable via back-swipe from the left edge

#### Scenario: Back-swipe reveals sidebar
- **WHEN** the user is on the TabView and swipes from the left edge
- **THEN** the TabView slides right and the sidebar is revealed as the root view

#### Scenario: No programmatic pendingNavigation
- **WHEN** any navigation action occurs
- **THEN** the system MUST NOT use `AppState.pendingNavigation` — all navigation is driven by the `NavigationStack` path

### Requirement: Sidebar contains smart filters and lists

The sidebar SHALL display a list of smart filters (Today, Tomorrow, Upcoming) followed by user-created reminder lists. Tapping a smart filter SHALL push the `MainTabView` (TabView) onto the navigation stack with the corresponding tab pre-selected. Tapping a list SHALL push `ListDetailView` onto the navigation stack.

The sidebar SHALL NOT have an edit/reorder mode for lists.

#### Scenario: Smart filter pushes TabView with correct tab
- **WHEN** the user taps "Tomorrow" in the sidebar
- **THEN** a `MainTabView` is pushed with the Tomorrow tab pre-selected
- **AND** the tab bar shows Today, Tomorrow, and Upcoming tabs

#### Scenario: List item pushes ListDetailView
- **WHEN** the user taps "Groceries" in the sidebar
- **THEN** `ListDetailView` is pushed for the Groceries list
- **AND** no tab bar is shown

#### Scenario: Back-swipe from either destination returns to sidebar
- **WHEN** the user is viewing either a TabView or ListDetailView
- **AND** swipes back from the left edge
- **THEN** the sidebar is revealed

#### Scenario: Tapping same active smart filter is a no-op
- **WHEN** the user is viewing the TabView on the Today tab
- **AND** taps "Today" in the sidebar
- **THEN** no duplicate push occurs — the current view remains unchanged

### Requirement: TabView retains per-tab navigation stacks

The `MainTabView` SHALL contain a `TabView` with three tabs (Today, Tomorrow, Upcoming). Each tab SHALL maintain its own independent `NavigationStack` for internal push navigation (e.g., task editing sheets). No list detail views SHALL be pushed onto these per-tab stacks.

#### Scenario: Tab switching is smooth and isolated
- **WHEN** the user taps the Tomorrow tab while on Today
- **THEN** the view switches to Tomorrow's content
- **AND** Today's scroll position and state are preserved

#### Scenario: Per-tab push navigation works independently
- **WHEN** the user taps a task row on the Today tab
- **THEN** a sheet editor appears (not a push onto the root NavigationStack)
- **AND** switching to the Tomorrow tab and back preserves the Today tab's state

### Requirement: Quick-capture uses default list

When the user creates a task via the quick-capture field in any tab's `ReminderSegmentDetailView`, the task SHALL be assigned to the default "Reminders" list, regardless of any previous sidebar selection.

#### Scenario: Quick-capture in TabView assigns to default list
- **WHEN** the user quick-captures a task from the Today tab
- **THEN** the task is created with `reminderList` set to the default "Reminders" list

### Requirement: AppState cleans up navigation state

`AppState` SHALL remove the properties `isSidebarOpen`, `selectedListId`, and `pendingNavigation`. These are no longer needed because the `NavigationStack` manages push/pop state natively and selection is implicit in the path.

#### Scenario: AppState has no navigation state
- **WHEN** the app is running
- **THEN** `AppState` MUST NOT expose `isSidebarOpen`, `selectedListId`, or `pendingNavigation`

### Requirement: SidebarContainer removed

The `SidebarContainer` view (ZStack overlay with backdrop, drag gesture, animation) SHALL be removed entirely. Its functionality is replaced by the `NavigationStack`'s native push/pop with standard back-swipe.

#### Scenario: No custom sidebar overlay exists
- **WHEN** the app runs
- **THEN** the view hierarchy MUST NOT include `SidebarContainer` — sidebar behavior uses standard `NavigationStack` push/pop

### Requirement: ReminderSegment trimmed to 3 cases

The `ReminderSegment` enum SHALL retain `.later` for sidebar navigation and task filtering use. The tab view in `SmartFilterTabbedView` SHALL NOT use `ReminderSegment.allCases` to build its tabs. Instead, the tab view SHALL use an explicit whitelist of `[.today, .tomorrow, .upcoming]` to ensure only three tabs appear.

All existing logic for `.later` in `ReminderSegmentLogic` and view code (`RescheduleToLater`, sidebar navigation link, filtering by `dueDate == nil`) SHALL remain unchanged.

#### Scenario: Tab bar shows exactly three tabs
- **WHEN** the user views any smart filter in the TabView
- **THEN** the tab bar SHALL display exactly three tabs: Today, Tomorrow, Upcoming
- **AND** the tab bar SHALL NOT display a "Later" tab

#### Scenario: Later remains in sidebar and filtering
- **WHEN** the user views the sidebar
- **THEN** the "Later" navigation link SHALL still appear
- **AND** tasks with no due date SHALL still appear when navigating to the Later view

#### Scenario: ReminderSegment enum retains later
- **WHEN** the app compiles
- **THEN** `ReminderSegment` SHALL have four cases: `.today`, `.tomorrow`, `.upcoming`, `.later`

### Requirement: ReminderRoute trimmed to list navigation only

The `ReminderRoute` enum SHALL contain only `.list(id:)`. The `.segment(ReminderSegment)` case SHALL be removed. The `.navigationDestination(for: ReminderRoute.self)` modifier SHALL be removed from the per-tab NavigationStacks in `MainTabView`.

#### Scenario: Only list route exists
- **WHEN** the app compiles
- **THEN** `ReminderRoute` has only the `.list(id:)` case
