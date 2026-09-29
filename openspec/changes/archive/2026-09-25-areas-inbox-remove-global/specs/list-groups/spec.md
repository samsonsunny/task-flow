## MODIFIED Requirements

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

### Requirement: Group creation via context menu

The user SHALL be able to create a new group from the context menu of any list row (except any Inbox bucket). The flow SHALL be: "Create New Group" → user enters group name → the group is created with its Inbox bucket → the list is moved into the new group.

#### Scenario: Create group from list context menu

- **WHEN** the user long-presses or right-clicks a list row
- **AND** selects "Create New Group" from the context menu
- **THEN** a text input prompt SHALL appear for the group name
- **AND** upon confirming a non-empty name, a new `ReminderListGroup` SHALL be created
- **AND** the new group SHALL have an Inbox bucket
- **AND** the selected list SHALL be moved into that group

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