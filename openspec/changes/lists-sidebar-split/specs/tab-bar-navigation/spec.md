## REMOVED Requirements

### Requirement: Root navigation is a 4-tab bottom TabView

**Reason**: The single-page segmented home and 4-tab `TabView` are both superseded by a `NavigationSplitView` root. The time segments move to the detail column and the Lists surface moves to the sidebar column.

**Migration**: See `split-view-navigation` for the root navigation requirements. The `TabView` root, `HomeSegment.organize`, and the per-tab `NavigationStack` layout are replaced by the split-view columns.

### Requirement: NavigationSplitView and sidebar removed

**Reason**: Reversed by the split-view model. `NavigationSplitView` is now the root navigation container, with the Lists surface in the sidebar column and the time home in the detail column.

**Migration**: `NavigationSplitView` is reintroduced as the root. The sidebar column hosts the Lists surface (groups + lists). The detail column hosts the Today/Tomorrow/Upcoming segmented time home and the capture bar.

## ADDED Requirements

### Requirement: Root navigation is a sidebar-split view

The app SHALL use a `NavigationSplitView` as its root navigation container. The sidebar column SHALL be the Lists surface (default Inbox, groups, and user lists). The detail column SHALL be the time home with a segmented control of exactly three segments (Today, Tomorrow, Upcoming). The `HomeSegment.organize` / Inbox segment SHALL be removed from the segmented control.

#### Scenario: App launches to the time home
- **WHEN** the app launches
- **THEN** the detail column shows the time home with Today selected
- **AND** the sidebar shows the Lists surface

#### Scenario: Selecting a list shows its tasks
- **WHEN** the user selects a list in the sidebar column
- **THEN** the detail column shows the selected list's tasks
- **AND** the navigation title matches the selected list name

#### Scenario: No capture bar on the Lists overview
- **WHEN** the user is viewing the Lists overview (root of the sidebar column)
- **THEN** the capture bar is not shown