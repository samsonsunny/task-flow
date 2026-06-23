## ADDED Requirements

### Requirement: Root navigation is a 4-tab bottom TabView

The app SHALL use a `TabView` with a bottom tab bar as its root navigation container. The tab bar SHALL display exactly four tabs: Today, Tomorrow, Upcoming, and Lists. Each tab SHALL wrap its content in an independent `NavigationStack`.

#### Scenario: App launches to Today tab
- **WHEN** the app launches
- **THEN** the user sees the Today tab selected in the bottom tab bar
- **AND** the Today tab's content is displayed

#### Scenario: Tapping tabs switches content
- **WHEN** the user taps the Tomorrow tab
- **THEN** the Tomorrow tab's content is displayed
- **AND** the Today tab's state (scroll position, quick-capture field) is preserved

#### Scenario: Each tab has its own NavigationStack
- **WHEN** the user navigates to a list detail in the Lists tab
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

### Requirement: Lists tab shows user-created lists

The Lists tab SHALL display all user-created `ReminderList` objects sorted alphabetically (with the default "Reminders" list first). Each row SHALL show the list name and a count of uncompleted tasks in that list. Tapping a list SHALL push `ListDetailView` for that list onto the Lists tab's `NavigationStack`.

The Lists tab SHALL have a toolbar button ("+") to create a new list. Tapping it SHALL present an alert with a text field for the list name.

#### Scenario: Lists tab shows all lists with task counts
- **WHEN** the user navigates to the Lists tab
- **THEN** all user-created lists are displayed
- **AND** each list shows an uncompleted task count badge

#### Scenario: Tapping a list pushes ListDetailView
- **WHEN** the user taps a list row in the Lists tab
- **THEN** `ListDetailView` for the selected list is pushed onto the Lists tab's NavigationStack

#### Scenario: Creating a new list from Lists tab
- **WHEN** the user taps the "+" toolbar button in the Lists tab
- **THEN** an alert appears with a text field for the list name
- **AND** entering a name and tapping "Create" inserts a new `ReminderList`

#### Scenario: Quick-capture in list detail assigns to that list
- **WHEN** the user is viewing a specific list in `ListDetailView` (pushed from Lists tab)
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

### Requirement: Later and Completed have no entry point

The Later and Completed views SHALL remain in the codebase but SHALL NOT have a navigation entry point in the new tab bar or any other visible navigation surface. Their functionality is accessible only through task context menus (reschedule to later) and completion actions (swipe to complete, toggle).

#### Scenario: No navigation to Later or Completed
- **WHEN** the user views any tab or navigates within the app
- **THEN** there is no button, link, or gesture to navigate to the Later or Completed views
