## ADDED Requirements

### Requirement: Root navigation is a 4-tab bottom TabView

The app SHALL use a `TabView` with a bottom tab bar as its root navigation container. The tab bar SHALL display exactly four tabs: Today, Tomorrow, Upcoming, and Later. Each tab SHALL wrap its content in an independent `NavigationStack`.

#### Scenario: App launches to Today tab
- **WHEN** the app launches
- **THEN** the user sees the Today tab selected in the bottom tab bar
- **AND** the Today tab's content is displayed

#### Scenario: Tapping tabs switches content
- **WHEN** the user taps the Tomorrow tab
- **THEN** the Tomorrow tab's content is displayed
- **AND** the Today tab's state (scroll position, quick-capture field) is preserved

#### Scenario: Each tab has its own NavigationStack
- **WHEN** the user navigates to a list detail in the Later tab
- **AND** switches to the Today tab
- **THEN** the Today tab shows its root content, not the list detail

### Requirement: Today tab shows overdue tasks inline

The Today tab SHALL display a collapsible "Overdue" section at the top of its task list when tasks are past their due date and not completed. The section SHALL be visible by default. Tapping the section header SHALL toggle its collapsed state. Tapping an overdue task row SHALL open the task editor sheet.

#### Scenario: Overdue section appears when tasks are overdue
- **WHEN** the user is on the Today tab
- **AND** there are incomplete tasks with due dates before today
- **THEN** an "Overdue" section appears at the top of the list
- **AND** each overdue task is shown with its due date

#### Scenario: Overdue section is collapsible
- **WHEN** the user taps the Overdue section header
- **THEN** the section collapses and overdue tasks are hidden
- **AND** tapping the header again expands the section

#### Scenario: No overdue section when none overdue
- **WHEN** the user is on the Today tab
- **AND** no incomplete tasks have due dates before today
- **THEN** the Overdue section is not displayed

### Requirement: Later tab shows groups and lists

The Later tab SHALL display user-created `ReminderList` objects optionally organized into `ReminderListGroup` sections, with the default "Inbox" list pinned at the top. Each row SHALL show the list name and a count of uncompleted tasks in that list. Tapping a list SHALL push `ListDetailView` for that list onto the Later tab's `NavigationStack`.

The Later tab SHALL have a button to create a new list.

Groups SHALL be displayed as expandable/collapsible sections. Ungrouped lists SHALL appear in a dedicated section below groups.

#### Scenario: Later tab shows groups and lists with task counts
- **WHEN** the user navigates to the Later tab
- **THEN** groups are shown as expandable sections with their contained lists
- **AND** ungrouped lists appear in a separate section
- **AND** the default "Inbox" list is pinned first
- **AND** each list shows an uncompleted task count badge

#### Scenario: Tapping a list pushes ListDetailView
- **WHEN** the user taps a list row in the Later tab
- **THEN** `ListDetailView` for the selected list is pushed onto the Later tab's NavigationStack

#### Scenario: Creating a new list from Later tab
- **WHEN** the user taps the create button in the Later tab
- **THEN** an alert appears with a text field for the list name
- **AND** entering a name and tapping "Create" inserts a new `ReminderList`

#### Scenario: Quick-capture in list detail assigns to that list
- **WHEN** the user is viewing a specific list in `ListDetailView` (pushed from Later tab)
- **AND** creates a task via quick-capture
- **THEN** the task is assigned to that list

### Requirement: NavigationSplitView and sidebar removed

The app SHALL NOT use `NavigationSplitView` as its root navigation. The inline sidebar `List` with smart sections (`SidebarSmartSections`) and list rows (`SidebarListsView`) SHALL be removed from `ContentView`. The `AppNav` enum SHALL be removed.

The `SidebarView.swift` file (currently unused) SHALL be removed from the project.

#### Scenario: No NavigationSplitView exists
- **WHEN** the app runs
- **THEN** the view hierarchy SHALL NOT contain `NavigationSplitView`
- **AND** the root view SHALL be a `TabView`

#### Scenario: SidebarView.swift is removed
- **WHEN** the project builds
- **THEN** the file `Views/Components/SidebarView.swift` SHALL NOT exist

### Requirement: Quick-capture in time tabs assigns to Inbox

When the user creates a task via the quick-capture field in any time-based tab's `ReminderSegmentDetailView`, the task SHALL be assigned to the default "Inbox" list.

#### Scenario: Quick-capture in time tabs assigns to Inbox
- **WHEN** the user quick-captures a task from the Today tab
- **THEN** the task is created with `reminderList` set to the default "Inbox" list

## REMOVED Requirements

### Requirement: Later and Completed have no entry point

**Reason**: The "Later" view concept was replaced by the Later tab, which serves as the permanent organizational home. The Later tab is now a first-class entry point in the tab bar.

**Migration**: Remove this requirement entirely. The Later tab replaces the "no entry point" rule.
