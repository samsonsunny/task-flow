# split-view-navigation

## Purpose

Define the app's root navigation surface: a `NavigationSplitView` with the Lists surface (the "where" axis) in the sidebar column and the time home (Today / Tomorrow / Upcoming, the "when" axis) in the detail column.

## Requirements

### Requirement: Root navigation is a sidebar-split view

The app SHALL use a `NavigationSplitView` as its root navigation container, with two columns:

- **Sidebar column**: the Lists surface (default Inbox list, groups, and user lists) — the "where" axis.
- **Detail column**: the time home — a segmented control with exactly three segments (Today, Tomorrow, Upcoming) plus a persistent capture bar — the "when" axis.

The inline `HomeSegment.organize` case SHALL be removed; the segmented control SHALL NOT include an Inbox/Organize segment.

#### Scenario: App launches to the time home
- **WHEN** the app launches
- **THEN** the detail column shows the time home with Today selected in the segmented control
- **AND** the sidebar column shows the Lists surface

#### Scenario: No Inbox segment in the time home
- **WHEN** the user inspects the segmented control in the detail column
- **THEN** the control contains exactly Today, Tomorrow, and Upcoming segments
- **AND** no Inbox/Organize segment is present

### Requirement: Lists surface lives in the sidebar column

The sidebar column SHALL display the default Inbox list, any user lists, and any `ReminderListGroup` sections, with uncompleted task counts per list. Tapping a list SHALL present that list's tasks in the detail column.

#### Scenario: Lists are in the sidebar, not the segmented control
- **WHEN** the user looks at the sidebar column
- **THEN** they see the default Inbox list, groups, and user lists with task-count badges
- **AND** tapping a list shows its tasks in the detail column

### Requirement: Segment switching stays zero-tap

Switching between Today, Tomorrow, and Upcoming SHALL happen through the segmented control in the detail column and SHALL NOT require a navigation push.

#### Scenario: Switching time segments
- **WHEN** the user taps a different segment in the segmented control
- **THEN** the detail column content switches to that segment's tasks immediately
- **AND** any pushed detail view pops back to the segment root

### Requirement: Selecting a list shows its tasks as the detail content

When the user selects a list in the sidebar column, the detail column SHALL show that list's tasks (`ListDetailView` content) as the primary content.

#### Scenario: Selecting a list from the sidebar
- **WHEN** the user taps a list row in the sidebar
- **THEN** the detail column shows the selected list's tasks
- **AND** the navigation title reflects the selected list name

#### Scenario: Returning to the time home
- **WHEN** the user deselects the list (or otherwise returns to the home surface)
- **THEN** the detail column shows the time home segmented control again