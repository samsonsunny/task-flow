## Purpose

Define areas (ReminderListGroup) as the organizational structure of the Later tab: the data model, bucket pinning, group CRUD, and drag-and-drop ordering of groups and lists.
## Requirements
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

Each group's Inbox bucket SHALL appear as the first list inside its group section, before all other member lists of that group, and SHALL display an inbox tray icon. The bucket's position is established by pointer (`group.defaultList`) and initial sortOrder, not by name matching.

#### Scenario: Bucket appears first in its group

- **WHEN** the user views a group section in the sidebar
- **THEN** the group's Inbox bucket SHALL be the first list shown
- **AND** remaining member lists SHALL follow in their persisted order

#### Scenario: Bucket pins against name-based detection absent

- **WHEN** two or more groups each have an Inbox bucket
- **THEN** each SHALL appear first only within its own group section
- **AND** no name-based comparison SHALL hoist any bucket across sections

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

The user SHALL be able to create a new group from the context menu of any list row (except any Inbox bucket). The flow SHALL be: "Create New Group" → user enters group name → the group is created with its Inbox bucket → the list is moved into the new group.

#### Scenario: Create group from list context menu

- **WHEN** the user long-presses or right-clicks a list row
- **AND** selects "Create New Group" from the context menu
- **THEN** a text input prompt SHALL appear for the group name
- **AND** upon confirming a non-empty name, a new `ReminderListGroup` SHALL be created
- **AND** the new group SHALL have an Inbox bucket
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

Lists within a group (including the Inbox bucket) SHALL be reorderable via drag-and-drop among themselves. The bucket SHALL remain pinned first: dragging the bucket is disallowed, so it SHALL always appear above other member lists. Group order and ungrouped-list reordering are unchanged except that no ungrouped section exists after migration.

#### Scenario: Drag reorders lists within a group

- **WHEN** the user long-presses and drags a member list to a new position within the same group below the bucket
- **THEN** the list SHALL appear at the dropped position
- **AND** all other member lists SHALL maintain their relative order

#### Scenario: Bucket cannot be moved from first position

- **WHEN** the user attempts to drag a group's Inbox bucket
- **THEN** the bucket SHALL remain the first list of the group
- **AND** no drag reordering SHALL move the list above it

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

After migration there SHALL be no list with `group == nil`. Any list lacking a group is reparented into the first group by the migration (one-time) and the reconciler (recurring backstop). New list creation, however, SHALL NOT default to ungrouped when a group context exists — new lists created from within a group section SHALL belong to that group; elsewhere they SHALL belong to the first group.

#### Scenario: Existing ungrouped list reparents

- **WHEN** the migration runs and a list has `group == nil`
- **THEN** the list SHALL be reparented into the first group
- **AND** the list's tasks SHALL remain unchanged

#### Scenario: New list within a group section

- **WHEN** the user creates a list while a group's section is active
- **THEN** the list SHALL have `group` set to that group
- **AND** SHALL appear as the last member list of that group (after the bucket)

#### Scenario: New list with no group context

- **WHEN** the user creates a list outside any group context
- **THEN** the list SHALL be assigned to the first group
- **AND** SHALL appear as the last member list of that group (after the bucket)

### Requirement: Empty groups are visible

Groups with no member lists SHALL still be displayed in the Lists tab. They SHALL show the group name, a chevron, a count of "0", and an empty area below when expanded.

#### Scenario: Empty group is visible
- **WHEN** a group has no member lists
- **THEN** the group header SHALL still appear in the Lists tab
- **AND** the task count SHALL display as 0
- **AND** expanding the group SHALL show an empty area

