# tab-bar-navigation

## Purpose

Define the app's root navigation container, its Home root, and how pushes resolve to time screens, list detail, and the secondary surfaces.

## MODIFIED Requirements

### Requirement: Root navigation is a 4-tab bottom TabView

The app SHALL use a single `NavigationStack` as its root navigation container, with `HomeView` as its root view. The app SHALL NOT use a bottom `TabView` as a navigation container and SHALL NOT display a tab bar. Home SHALL own the capture bar; pushed screens SHALL read the selected area and capture target from `AppState`.

#### Scenario: App launches to Home
- **WHEN** the app launches
- **THEN** the user sees `HomeView` as the root of a `NavigationStack`
- **AND** no bottom tab bar is displayed

#### Scenario: No tab bar exists anywhere
- **WHEN** the user navigates to any screen
- **THEN** no tab bar SHALL be present
- **AND** the app's view hierarchy SHALL contain no `TabView` used as a navigation container

#### Scenario: Pushes use one stack
- **WHEN** the user pushes a list detail and then pops back
- **THEN** the user SHALL return to `HomeView` with its scroll position and section collapse state preserved
- **AND** no parallel navigation stack SHALL exist

#### Scenario: Home capture bar is not duplicated on pushes
- **WHEN** the user pushes a time screen
- **THEN** the capture bar SHALL be rendered by that screen
- **AND** Home's capture bar SHALL NOT also be visible underneath

### Requirement: Today tab shows overdue tasks inline

The pushed Today screen SHALL display a collapsible "Overdue" section at the top of its task list when tasks in the selected area are past their due date and not completed. The section SHALL be visible by default. Tapping the section header SHALL toggle its collapsed state. Tapping an overdue task row SHALL open the task editor sheet. Home SHALL additionally surface the selected area's overdue count in its summary block, and the summary row SHALL be the entry point to this screen.

#### Scenario: Overdue section appears when tasks are overdue
- **WHEN** the user is on the Today screen
- **AND** the selected area has incomplete tasks with due dates before today
- **THEN** an "Overdue" section appears at the top of the list
- **AND** each overdue task is shown with its due date

#### Scenario: Overdue section is collapsible
- **WHEN** the user taps the Overdue section header
- **THEN** the section collapses and overdue tasks are hidden
- **AND** tapping the header again expands the section

#### Scenario: No overdue section when none overdue
- **WHEN** the user is on the Today screen
- **AND** the selected area has no incomplete tasks with due dates before today
- **THEN** the Overdue section is not displayed

#### Scenario: Overdue section is area-scoped
- **WHEN** Work has overdue tasks and Personal does not
- **AND** the user is on the Today screen with Personal selected
- **THEN** no Overdue section SHALL be displayed
- **AND** a cross-area nudge SHALL disclose Work's overdue count

#### Scenario: Home summary pushes Today
- **WHEN** the user taps the Today row in Home's summary block
- **THEN** the Today screen SHALL be pushed
- **AND** it SHALL be scoped to the selected area

### Requirement: NavigationSplitView and sidebar removed

The app SHALL NOT use `NavigationSplitView` as its root navigation, and the inline sidebar list-of-lists SHALL be removed entirely. The `AppNav` enum SHALL be removed. The `SidebarView.swift` file (currently unused) SHALL be removed from the project. `TaskFlow/Features/Lists/ListView.swift` (the `ListsSidebarView` surface) SHALL be removed from the project.

#### Scenario: No NavigationSplitView exists
- **WHEN** the app runs
- **THEN** the view hierarchy SHALL NOT contain `NavigationSplitView`
- **AND** the root view SHALL be a `NavigationStack` rooted at `HomeView`

#### Scenario: Sidebar list-of-lists surface is removed
- **WHEN** the project builds
- **THEN** `Views/Components/SidebarView.swift` SHALL NOT exist
- **AND** `TaskFlow/Features/Lists/ListView.swift` SHALL NOT exist

#### Scenario: No screen shows a list of lists
- **WHEN** the user navigates the app
- **THEN** no screen SHALL present a list-of-lists with area `DisclosureGroup` sections
- **AND** lists SHALL appear only as sections on Home scoped to the selected area, or as a pushed list detail

### Requirement: Quick-capture in time tabs assigns to Inbox

When the user creates a task via the capture bar on a pushed time screen (`Today`, `Tomorrow`, `Upcoming`), the task SHALL be assigned to the Inbox bucket of the selected area, resolved by pointer.

#### Scenario: Quick-capture in time screens assigns to the selected area's Inbox
- **WHEN** the user captures a task from the Today screen with Personal selected
- **THEN** the task is created with `reminderList` set to Personal's Inbox bucket

## REMOVED Requirements

### Requirement: Later tab shows groups and lists

**Reason**: There is no Later tab. Root navigation is a single `NavigationStack` rooted at Home, and area group sections with expandable/collapse state, an ungrouped section, and a per-section create button are all superseded by Home's area-scoped list sections and the removal of all area CRUD.

**Migration**: Home shows every list in the selected area as a collapsible section with the area's Inbox bucket pinned first, each header carrying an uncompleted-task count. Tapping a list pushes `ListDetailView`. List creation is available from Home's overflow and creates the list in the selected area, with no group picker.
