## MODIFIED Requirements

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
