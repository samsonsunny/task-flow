## REMOVED Requirements

### Requirement: NavigationStack root with sidebar

**Reason**: The sidebar approach was replaced by a 4-tab `TabView` as the sole navigation surface. No sidebar exists in the current architecture.

**Migration**: All sidebar-related code has been removed. Navigation is handled entirely by the `TabView` in `MainTabView`.

### Requirement: Sidebar contains smart filters and lists

**Reason**: The sidebar no longer exists. Smart filters (Today, Tomorrow, Upcoming) are tabs in the tab bar. Lists are accessed via the Later tab.

**Migration**: Remove any remaining sidebar references. Use `MainTabView` with tab selection for navigation.

### Requirement: TabView retains per-tab navigation stacks

**Reason**: This requirement described TabView behavior within a sidebar context that no longer exists. The current architecture uses `MainTabView` directly as the root.

**Migration**: Use the `tab-bar-navigation` spec for the current navigation model.

### Requirement: Quick-capture uses default list

**Reason**: Sidebar context for this requirement is obsolete. Quick-capture behavior is now specified in the `tab-bar-navigation` spec.

**Migration**: See `tab-bar-navigation/spec.md` for the current quick-capture requirement.

### Requirement: AppState cleans up navigation state

**Reason**: The navigation state properties (`isSidebarOpen`, `selectedListId`, `pendingNavigation`) were already removed in a previous refactor. This requirement is satisfied.

**Migration**: Ensure `AppState` contains no navigation-related state.

### Requirement: SidebarContainer removed

**Reason**: `SidebarContainer` was already removed. This requirement is satisfied and the spec is being archived.

**Migration**: Ensure no `SidebarContainer` view exists in the codebase.

### Requirement: ReminderSegment trimmed to 3 cases

**Reason**: This requirement was specific to a previous `SmartFilterTabbedView` and sidebar context. The `ReminderSegment.later` case has been removed entirely as dead code. The tab bar uses an explicit 4-tab structure.

**Migration**: The `ReminderSegment` enum now contains `.today`, `.tomorrow`, `.upcoming`, `.overdue`. The tab bar shows four tabs: Today, Tomorrow, Upcoming, Later.

### Requirement: ReminderRoute trimmed to list navigation only

**Reason**: This requirement was specific to a previous navigation architecture. The current architecture uses `MainTabView` with per-tab `NavigationStack` instances.

**Migration**: Ensure `ReminderRoute` only contains `.list(id:)` if it still exists in the codebase.
