## Context

The current `ContentView` uses a `ZStack` containing a `TabView` (3 tabs) and a custom `SidebarContainer` overlay. The sidebar is driven by `AppState` properties (`isSidebarOpen`, `selectedListId`, `pendingNavigation`) with manual drag gestures and backdrop handling. Selecting a list from the sidebar writes to `pendingNavigation`, which an `.onChange` handler in `ContentView` observes and appends to the active tab's navigation path. This indirection causes context loss on tab switch, race conditions on rapid taps, and non-standard gesture behavior.

iOS 26 deployment target means all modern SwiftUI APIs (`NavigationStack` with typed paths, `Observable`) are available.

## Goals / Non-Goals

**Goals:**
- Replace custom ZStack sidebar overlay with NavigationStack-native navigation
- Auto-push TabView on launch so users land on Today's tasks immediately
- Make sidebar accessible via standard iOS back-swipe gesture
- Eliminate `pendingNavigation` and `selectedListId` from `AppState`
- Trim `ReminderSegment` to only `.today`, `.tomorrow`, `.upcoming`
- Trim `ReminderRoute` to only `.list(id:)`
- Quick-capture in TabView mode always assigns to default "Reminders" list
- Remove `SidebarContainer` entirely

**Non-Goals:**
- iPad adaptation (`NavigationSplitView` deferred)
- State restoration on app restart
- List reordering / editing in sidebar
- Adding new smart filters beyond Today, Tomorrow, Upcoming
- Changing the data model, query patterns, or SwiftData setup

## Decisions

### Decision 1: NavigationStack with typed path over NavigationSplitView

**Chosen:** `NavigationStack` root with a `NavItem` enum path.

```swift
enum NavItem: Hashable {
    case tabView(initialTab: ReminderSegment)
    case listDetail(id: ReminderList.ID)
}
```

The path is initialized to `[.tabView(initialTab: .today)]` so the TabView auto-pushes on launch. The sidebar root view is never seen initially — the back-swipe reveals it.

**Alternatives considered:**
- `NavigationSplitView`: Better for iPad but adds complexity. Deferred.
- Manual `ZStack` with push simulation: The current approach, being replaced.
- `TabView` as root with `.tabViewSidebar`: Possible with iOS 18+ but the sidebar in this API is an overlay, not a NavigationStack root — it doesn't support pushing `ListDetailView` within its own context.

### Decision 2: Sidebar action drives path directly, not via AppState

**Chosen:** Sidebar buttons call a closure or directly append to the `NavigationStack` path binding.

```swift
// SidebarView receives a binding or callback
Button(list.name) {
    onSelect(.listDetail(id: list.id))
}
```

This eliminates `AppState.pendingNavigation`, `AppState.isSidebarOpen`, and `AppState.selectedListId` — all three become unnecessary because the NavigationStack manages push/pop natively and selection is implicit in the path.

### Decision 3: ReminderSegment trimmed to 3 cases

**Chosen:** `.today`, `.tomorrow`, `.upcoming` remain. `.scheduled`, `.allReminders`, `.completed`, `.overdue`, `.later` are removed.

The Overdue `NavigationLink` in `ReminderSegmentDetailView` that pushed `ReminderRoute.segment(.overdue)` is removed. The tab's internal NavigationStack no longer has a `.navigationDestination` for `ReminderRoute.segment`.

### Decision 4: Quick-capture always uses default list

**Chosen:** `resolvedQuickCaptureList()` in `ReminderSegmentDetailView` ignores `appState.selectedListId` and always resolves to the "Reminders" default list.

**Alternatives considered:**
- Using last sidebar selection: Would require re-adding `selectedListId` tracking. Unnecessary complexity for this use case.

### Decision 5: MainTabView as extracted component

**Chosen:** Extract the current `TabView` + per-tab `NavigationStack` into a standalone `MainTabView` component.

```swift
struct MainTabView: View {
    @State private var selectedTab: ReminderSegment
    let initialTab: ReminderSegment

    init(initialTab: ReminderSegment) {
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }
    // ...existing TabView + NavigationStack per tab...
}
```

This keeps `ContentView` lean and makes `MainTabView` a reusable pushed destination.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| [Launch animation] Auto-pushing on launch may show a brief flash of the sidebar before the TabView slides in | The `NavigationStack` path is initialized before the first render — no flash. Test on device to confirm. |
| [TabView back swipe] The back-swipe from TabView to sidebar is aggressive — users might accidentally swipe back when trying to scroll to top | Standard iOS behavior. Users are familiar with it from Mail, Settings, etc. The edge-swize zone is narrow (~20pts). |
| [Sidebar state on re-push] If user taps "Today" from sidebar while already viewing the Today TabView, do we push a duplicate? | The sidebar action should check the current path and pop to existing TabView instead of pushing a new one. Use `NavigationStack` path manipulation or a simple guard. |
| [Per-tab list context lost] Task editing within a tab pushes sheets — these are unaffected since sheets are local to each tab's NavigationStack | No action needed — sheets are orthogonal to the root navigation. |
| [ReminderSegment removal] Other code may reference the removed enum cases | Grep for all usages. The removed cases (scheduled, allReminders, completed, overdue, later) are used in `ReminderSegmentLogic.filteredTasks()` and `ReminderSegments.swift` static properties. Remove the cases and their associated switch branches. |
| [NavItem conformance] `ReminderList.ID` is `PersistentIdentifier` which may not be `Hashable` by default in SwiftData | Add explicit `Hashable` conformance or use a `String` wrapper for the list ID in `NavItem`. |

## Open Questions

- Should the sidebar show task counts for each smart filter (e.g., "Today (12)")? Currently the tab view shows counts. The sidebar could show them too for consistency.
- What happens when the user taps the same smart filter they're already viewing? Should it pop to the existing TabView or do nothing? Recommend: do nothing (no-op guard).
