## Context

The app's root navigation is a `NavigationSplitView` with an inline sidebar `List(selection:)` and a detail pane. The sidebar drives the detail pane by mutating a `selection: AppNav?` state. This pattern is iPad-native and adds unnecessary complexity for iPhone: a selection state enum, smart filter sections in the sidebar, and a large `switch` in the detail pane. An unused `MainTabView` (3-tab `TabView`) and `SidebarView` exist as vestiges of an abandoned refactor.

iOS 26 deployment target is retained. The app is iPhone-only. No iPad-specific adaptation is in scope.

## Goals / Non-Goals

**Goals:**
- Replace `NavigationSplitView` with a 4-tab bottom `TabView` as the root navigation
- Today, Tomorrow, Upcoming tabs mirror the existing tab behavior with per-tab `NavigationStack` for sheets
- New Lists tab shows user-created lists, tapping pushes `ListDetailView` within that tab's `NavigationStack`
- Overdue tasks appear as a collapsible section at the top of the Today tab
- Remove the inline sidebar `List`, `selection` state, `AppNav` enum, `SidebarSmartSections`, and `SidebarListsView` from `ContentView`
- Remove the unused `SidebarView.swift` file
- Preserve all detail views, task rows, quick-capture, sheets, and data model unchanged

**Non-Goals:**
- Adding Later or Completed entry points (views remain in code, no navigation surface)
- iPad-specific adaptation or `NavigationSplitView` fallback
- State restoration beyond what the tabs provide natively
- Changes to `ReminderSegment`, `ReminderSegmentLogic`, or the data model
- Changes to sheet-based editing (`ReminderEditorView`, `TaskScheduleDatePickerSheet`)
- Changes to quick-capture logic (`resolvedQuickCaptureList()`, `commitQuickCapture()`)

## Decisions

### Decision 1: TabView root over NavigationStack root

**Chosen:** `TabView` as the root container. Each tab has its own `NavigationStack`.

```swift
TabView {
    TodayTabView()
        .tabItem { Label("Today", systemImage: "calendar.circle.fill") }

    ReminderSegmentDetailView(segment: .tomorrow)
        .tabItem { Label("Tomorrow", systemImage: "sunrise.fill") }

    ReminderSegmentDetailView(segment: .upcoming)
        .tabItem { Label("Upcoming", systemImage: "calendar.badge.clock") }

    ListsTabView()
        .tabItem { Label("Lists", systemImage: "list.bullet") }
}
```

**Alternatives considered:**
- `NavigationStack` root with content-only tabs: Would require a custom tab-like implementation. Unnecessary — `TabView` gives native tab bar behavior for free.
- `NavigationSplitView` with reduced sidebar: Preserves the sidebar column, which is exactly what we're removing.
- Inline everything in `ContentView` without `MainTabView`: Possible, but `MainTabView` already exists and is the natural home for tab logic.

### Decision 2: Overdue section via TodayTabView wrapper

**Chosen:** Create a `TodayTabView` wrapper that composes an overdue section + existing `ReminderSegmentDetailView(segment: .today)`. The wrapper owns the overdue toggle state.

```swift
struct TodayTabView: View {
    @State private var showOverdue = true
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    private var overdueTasks: [TaskItem] {
        ReminderSegmentLogic.filteredTasks(allTasks, for: .overdue, now: Date())
    }

    var body: some View {
        NavigationStack {
            // Overdue section at top, collapsible
            // Then ReminderSegmentDetailView(segment: .today) below
        }
    }
}
```

**Alternatives considered:**
- Modify `ReminderSegmentDetailView` to accept an `includeOverdue` parameter: Adds complexity to a shared component that 3 tabs use. The overdue section is Today-only.
- Inline the Today content directly: Duplicates `ReminderSegmentDetailView` logic. The wrapper approach reuses it.

### Decision 3: Lists tab via ListsTabView wrapper

**Chosen:** Create a `ListsTabView` that shows all user `ReminderList` objects with task counts, a "+" toolbar button for new lists, and `NavigationLink` to `ListDetailView`. The tab has its own `NavigationStack`.

The list rows mirror the current `SidebarListsView` appearance (icon, name, count badge) but as navigation links within the tab, not as a sidebar list.

```
┌──────────────────────────────┐
│ All Lists            [+]    │
│                              │
│  📋 Reminders       (5)     │
│  📋 Groceries       (12)    │
│  📋 Work             (3)    │
└──────────────────────────────┘
```

Tapping a list pushes `ListDetailView(listID:)` onto the tab's `NavigationStack`. Creating a new list uses `.alert` (same pattern as current ContentView).

### Decision 4: ContentView becomes a thin shell

`ContentView` is rewritten to simply instantiate `MainTabView`. All sidebar logic (`selection`, `SidebarSmartSections`, `SidebarListsView`, `migrateOrphanedTasks()`) moves or is removed. `migrateOrphanedTasks()` and `backfillSortOrdersIfNeeded()` are moved to an `.onAppear` in the root `TaskFlowApp`.

### Decision 5: AppNav enum deleted

`AppNav` is only used by the `NavigationSplitView` pattern. With tabs replacing the sidebar's role, `AppNav` has no consumers. The `switch selection` detail view dispatch is replaced by direct tab content.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| [Tab bar too crowded] 4 tabs with "Lists" label may feel cramped on smaller iPhones | 4 tabs is within Apple HIG (2-5). Each label is short. No title truncation expected. |
| [Overdue discoverability] Users may not notice overdue tasks at top of Today tab | The section header is visually distinct (error color, exclamation icon). Collapsible by default or persistent when > 0. |
| [Lists tab redundancy] Lists tab duplicates functionality that was previously sidebar-only, but removes the ability to switch between a list and a smart filter in one tap | Users now switch via tab bar instead of sidebar. This is a deliberate trade-off for simpler navigation. |
| [Later/Completed hidden] Users who used these sidebar items lose access | The views remain in the codebase. A future settings/profile screen can re-add entry points. |
| [Two kinds of "TabView"] The root TabView (bottom bar) and SmartFilterTabbedView (segmented) coexist, potentially confusing | `SmartFilterTabbedView` is removed as unused — each bottom tab directly embeds its segment's content, not a sub-TabView. |
| [quick-capture in Lists tab] Assigning to the selected list vs. default list changes current behavior for the Lists tab | This is the correct behavior — if the user is browsing a specific list, new tasks should go to that list. If on the Lists tab root (not in a specific list), resolve to default list. |
