## Why

The app uses a `NavigationSplitView` with a sidebar column for navigation, but this is an iPad-oriented pattern (side-by-side columns). On iPhone, a bottom tab bar is the standard iOS navigation pattern and matches user expectations. The sidebar also carries complexity — an inline `List(selection:)`, smart section filtering, and state management for selection — that can be eliminated entirely.

## What Changes

- **BREAKING**: Replace `NavigationSplitView` sidebar column with a 4-tab bottom `TabView` (Today, Tomorrow, Upcoming, Lists)
- Overdue tasks are shown inline as a collapsible section at the top of the Today tab
- Later and Completed views are removed from the navigation (their view code remains in the project, just no entry point)
- `MainTabView.swift` (currently unused) is adapted as the root tab container
- `SidebarView.swift` (currently unused) is removed
- The inline sidebar `List` in `ContentView` is removed along with `selection` state
- Lists tab shows all user-created lists with task counts; tapping a list pushes `ListDetailView`
- Quick-capture in the Lists tab assigns to the selected list; quick-capture in Today/Tomorrow/Upcoming tabs continues to assign to the default "Reminders" list
- The `Lists` tab's `NavigationStack` is for list navigation only — it does not show smart filters
- No changes to the data model, task rows, quick-capture logic, or sheets

## Capabilities

### New Capabilities
- `tab-bar-navigation`: The app uses a 4-tab bottom `TabView` (Today, Tomorrow, Upcoming, Lists) as its root navigation. Each tab has its own `NavigationStack`. The Today tab shows overdue tasks inline. The Lists tab shows user-created lists and pushes `ListDetailView` on selection. The sidebar column is removed entirely.

### Modified Capabilities
<!-- No existing specs change — sidebar-navigation spec was never implemented as written (code uses NavigationSplitView, not NavigationStack). This replaces that approach entirely. -->

## Impact

- `App/ContentView.swift` — Rewritten: `NavigationSplitView` → `TabView`; sidebar `List` + `selection` state removed; `SidebarSmartSections` removed
- `Features/Reminders/MainTabView.swift` — Adapted from 3-tab to 4-tab; Lists tab added; overdue section added to Today tab; used as root container
- `Views/Components/SidebarView.swift` — Removed (unused)
- `App/AppState.swift` — Unchanged (already empty/clean)
