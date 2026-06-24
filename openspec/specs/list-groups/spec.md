## ADDED Requirements

### Requirement: ReminderListGroup data model

The system SHALL introduce a `ReminderListGroup` SwiftData model to represent a named group of reminder lists. A `ReminderListGroup` SHALL have a one-to-many relationship with `ReminderList`. Each `ReminderList` MAY have an optional reference to a `ReminderListGroup`. Groups SHALL be single-level only (no nested sub-groups).

The `ReminderListGroup` model SHALL contain:
- `name: String` — the display name of the group
- `sortOrder: String?` — fractional string for drag-reorder positioning
- `createdAt: Date` — creation timestamp

The `ReminderList` model SHALL gain an optional inverse relationship:
- `group: ReminderListGroup?` — nil means the list is ungrouped

#### Scenario: Group model has required properties
- **WHEN** a `ReminderListGroup` is created
- **THEN** it SHALL have a non-empty `name` and a valid `createdAt`

#### Scenario: List optionally belongs to a group
- **WHEN** a `ReminderList` is created
- **THEN** its `group` property SHALL default to `nil` (ungrouped)

#### Scenario: Groups cannot contain sub-groups
- **WHEN** any operation occurs
- **THEN** a `ReminderListGroup` SHALL NOT contain another `ReminderListGroup`

### Requirement: Migration is additive with no data loss

The schema migration from the current version to the version including `ReminderListGroup` SHALL be lightweight and additive. All existing `ReminderList` objects SHALL retain their `group` as `nil`. No existing data SHALL be modified or deleted.

#### Scenario: Existing lists remain ungrouped after migration
- **WHEN** the app launches after the update
- **THEN** all existing `ReminderList` objects SHALL have `group == nil`

#### Scenario: Existing task data is preserved
- **WHEN** the app launches after the update
- **THEN** all existing `TaskItem` objects and their relationships SHALL be unchanged

### Requirement: Default list is pinned at top

The default "Reminders" list SHALL always appear as the first item in the Lists tab, above all groups and ungrouped lists. It SHALL NOT be movable into a group or reorderable.

#### Scenario: Reminders list appears first
- **WHEN** the user views the Lists tab
- **THEN** the "Reminders" list SHALL be the first item displayed
- **AND** it SHALL appear before any groups or other lists

#### Scenario: Reminders list cannot be grouped
- **WHEN** the user attempts to move the "Reminders" list into a group
- **THEN** the context menu SHALL NOT offer group options for this list

### Requirement: Groups display as expandable sections

In the Lists tab, each group SHALL display as a section header with an expand/collapse chevron. Tapping the header SHALL toggle the visibility of its member lists. The expanded/collapsed state SHALL persist across app restarts.

Each group section header SHALL display:
- The group name
- A chevron icon indicating expanded/collapsed state
- A count of incomplete tasks across all member lists (visible in both states)

#### Scenario: Tapping group header toggles expand/collapse
- **WHEN** the user taps a group header
- **THEN** if the group is collapsed, it SHALL expand to show its member lists
- **AND** if the group is expanded, it SHALL collapse to hide its member lists

#### Scenario: Collapsed group shows task count
- **WHEN** the group is collapsed
- **THEN** the header SHALL show the total count of incomplete tasks across all its lists

#### Scenario: Expanded/collapsed state persists
- **WHEN** the user expands a group, closes the app, and reopens
- **THEN** the group SHALL still be expanded

### Requirement: Group creation via context menu

The user SHALL be able to create a new group from the context menu of any list row (except the default "Reminders" list). The flow SHALL be: "Create New Group" → user enters group name → the list is moved into the new group.

#### Scenario: Create group from list context menu
- **WHEN** the user long-presses or right-clicks a list row
- **AND** selects "Create New Group" from the context menu
- **THEN** a text input prompt SHALL appear for the group name
- **AND** upon confirming a non-empty name, a new `ReminderListGroup` SHALL be created
- **AND** the selected list SHALL be moved into that group

### Requirement: Move list to group via context menu

The context menu on a list row SHALL include a "Move to Group" submenu listing all existing groups plus an option to ungroup the list. Selecting a group SHALL assign the list to that group.

#### Scenario: Move list to existing group
- **WHEN** the user opens the context menu on a list row
- **AND** selects "Move to Group"
- **THEN** a submenu SHALL display all existing group names
- **AND** selecting a group SHALL set the list's `group` to that group

#### Scenario: Ungroup a list
- **WHEN** the user opens the context menu on a grouped list
- **AND** selects "Move to Group" → "None"
- **THEN** the list's `group` SHALL be set to `nil`

#### Scenario: Create new group via context menu
- **WHEN** the user opens the context menu on a list row
- **AND** selects "Move to Group"
- **THEN** the submenu SHALL include a "New Group..." option
- **AND** selecting it SHALL prompt for a group name and create the group with the list moved into it

### Requirement: Drag-and-drop reorder of groups

The user SHALL be able to reorder groups by long-pressing and dragging group headers. The group order SHALL persist across app restarts using fractional string `sortOrder`.

#### Scenario: Drag reorders groups
- **WHEN** the user long-presses and drags a group header to a new position among other groups
- **THEN** the group SHALL appear at the dropped position
- **AND** all other groups SHALL maintain their relative order
- **AND** the new order SHALL persist after relaunch

### Requirement: Drag-and-drop reorder of lists within groups

The user SHALL be able to reorder lists within a group by long-pressing and dragging a list row. The list order within each group SHALL persist across app restarts.

#### Scenario: Drag reorders lists within a group
- **WHEN** the user long-presses and drags a list to a new position within the same group
- **THEN** the list SHALL appear at the dropped position
- **AND** all other lists in that group SHALL maintain their relative order

### Requirement: Drag-and-drop reorder of ungrouped lists

Ungrouped lists (those not assigned to any group) SHALL be reorderable via drag-and-drop among themselves. They SHALL appear below all groups in the Lists tab.

#### Scenario: Drag reorders ungrouped lists
- **WHEN** the user long-presses and drags an ungrouped list to a new position among other ungrouped lists
- **THEN** the list SHALL appear at the dropped position
- **AND** all other ungrouped lists SHALL maintain their relative order

### Requirement: Drag list between groups

The user SHALL be able to drag a list from one group to another, or from a group to the ungrouped section. This SHALL update the list's `group` and `sortOrder` appropriately.

#### Scenario: Drag list from one group to another
- **WHEN** the user drags a list from group A into group B
- **THEN** the list's `group` SHALL be updated to group B
- **AND** the list SHALL appear at the dropped position within group B

#### Scenario: Drag list from group to ungrouped
- **WHEN** the user drags a list from a group to the ungrouped section
- **THEN** the list's `group` SHALL be set to `nil`
- **AND** the list SHALL appear at the dropped position among ungrouped lists

### Requirement: New lists are ungrouped by default

When a new `ReminderList` is created via the "+" button in the Lists tab, it SHALL be ungrouped (`group == nil`) and appear at the end of the ungrouped list section.

#### Scenario: New list is ungrouped
- **WHEN** the user creates a new list from the Lists tab
- **THEN** the list SHALL have `group == nil`
- **AND** SHALL appear as the last item in the ungrouped section

### Requirement: Empty groups are visible

Groups with no member lists SHALL still be displayed in the Lists tab. They SHALL show the group name, a chevron, a count of "0", and an empty area below when expanded.

#### Scenario: Empty group is visible
- **WHEN** a group has no member lists
- **THEN** the group header SHALL still appear in the Lists tab
- **AND** the task count SHALL display as 0
- **AND** expanding the group SHALL show an empty area
