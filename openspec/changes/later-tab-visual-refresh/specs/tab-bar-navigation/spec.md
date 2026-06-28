## MODIFIED Requirements

### Requirement: Later tab shows groups and lists

The Later tab SHALL display user-created `ReminderList` objects optionally organized into `ReminderListGroup` sections, with the default "Inbox" list pinned at the top and visually distinct from user-created lists. Each row SHALL show the list name and a count of uncompleted tasks in that list. Tapping a list SHALL push `ListDetailView` for that list onto the Later tab's `NavigationStack`.

The Later tab SHALL have a button to create a new list.

Groups SHALL be displayed as expandable/collapsible sections. Ungrouped lists SHALL appear in a dedicated section above groups. A thin visual divider SHALL separate the ungrouped section from the grouped sections below.

#### Scenario: Later tab shows groups and lists with task counts
- **WHEN** the user navigates to the Later tab
- **THEN** groups are shown as expandable sections with their contained lists
- **AND** ungrouped lists appear in a separate section above groups
- **AND** a thin divider separates the ungrouped section from groups
- **AND** the default "Inbox" list is pinned first with distinct visual treatment
- **AND** each list shows an uncompleted task count badge

## ADDED Requirements

### Requirement: Later tab rows match app font and spacing standards

All list rows in the Later tab root view SHALL use 17pt regular font for list names, matching the `TaskRowView` title font. Row spacing SHALL use `listRowInsets` with top/bottom of 3pt, matching the task row layout in `ReminderSegmentDetailView` and `ListDetailView`. Default list row separators SHALL be hidden.

#### Scenario: List row uses 17pt font
- **WHEN** the Later tab renders a list row
- **THEN** the list name SHALL use 17pt regular font

#### Scenario: List row uses task-standard spacing
- **WHEN** the Later tab renders a list row
- **THEN** the row SHALL have `listRowInsets` with top and bottom of 3pt

#### Scenario: List row separators are hidden
- **WHEN** the Later tab renders a list row
- **THEN** the row SHALL have no visible separator

### Requirement: Inbox row is visually distinct

The default "Inbox" list row SHALL be visually distinguishable from user-created list rows. At minimum, it SHALL use a different icon (`tray` vs `list.bullet` — already implemented) and SHALL have a distinct background or badge treatment to communicate its role as a staging area.

#### Scenario: Inbox row has distinct appearance
- **WHEN** the user views the Later tab
- **THEN** the Inbox row SHALL be visually distinguishable from user-created list rows
