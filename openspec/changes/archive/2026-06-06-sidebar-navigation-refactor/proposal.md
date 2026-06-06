## Why

The sidebar is built as a custom ZStack overlay with a fragile `pendingNavigation` hack to push list detail views onto tab NavigationStacks. This causes context loss when switching tabs, race conditions on rapid taps, no standard edge-swipe gesture, and tab title/content mismatches. The navigation model needs to be replaced with a standard `NavigationStack` root where the sidebar is the hub and all destinations are pushed onto it.

## What Changes

- **BREAKING**: Replace `ContentView`'s `TabView` + ZStack sidebar overlay with a single `NavigationStack` where the sidebar (`SidebarView`) is the root
- On launch, the navigation stack auto-pushes the TabView (starting on Today) so the user lands on tasks immediately
- The sidebar becomes accessible via the native back-swipe gesture from the TabView
- Sidebar contains three smart filters (Today, Tomorrow, Upcoming) and user-created lists
- Tapping a smart filter pushes the TabView with the corresponding tab pre-selected
- Tapping a list pushes `ListDetailView` directly (no tab bar, self-contained)
- Sidebar no longer has an edit/reorder mode for lists
- Quick-capture in TabView mode always assigns to the default "Reminders" list
- `AppState` shrinks: remove `isSidebarOpen`, `pendingNavigation`, `selectedListId`
- `ReminderSegment` enum is trimmed to only `.today`, `.tomorrow`, `.upcoming`
- `ReminderRoute` enum is trimmed to only `.list(id:)`
- Custom `SidebarContainer` ZStack overlay + backdrop + drag gesture is removed
- `TabView` retains its internal per-tab `NavigationStack` for each tab's own push navigation (e.g., task editing sheets)
- No iPad-specific work; `NavigationSplitView` deferred
- No state restoration (existing limitation, not addressed here)

## Capabilities

### New Capabilities
- `sidebar-navigation`: The sidebar serves as the root navigation hub with smart filters and lists, using NavigationStack path-based navigation and standard iOS back-swipe gestures

### Modified Capabilities
<!-- None - no existing specs are changing at the requirement level -->

## Impact

- `App/ContentView.swift` — Rewritten: TabView + ZStack → NavigationStack with sidebar root and auto-push
- `App/AppState.swift` — Truncated: remove isSidebarOpen, pendingNavigation, selectedListId
- `Views/Components/SidebarContainer.swift` — Removed entirely
- `Views/Components/SidebarView.swift` — Adapted for NavigationStack root context (no overlay, no pendingNavigation writes)
- `Features/Reminders/ReminderSegments.swift` — Trimmed to 3 cases; associated logic updated
- `App/ContentView.swift` — ReminderRoute trimmed; internal navigationDestinations updated
- `Features/Reminders/ReminderSegmentDetailView.swift` — quick-capture list resolution simplified (always default list)
- `Features/Reminders/ListDetailView.swift` — Unchanged (already self-contained)
