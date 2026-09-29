## Purpose

Define areas (ReminderListGroup) as the organizational structure of the Later tab: the data model, bucket pinning, group CRUD, and drag-and-drop ordering of groups and lists.

## MODIFIED Requirements

### Requirement: ReminderListGroup data model

The system SHALL maintain a `ReminderListGroup` SwiftData model to represent a named group of reminder lists. A `ReminderListGroup` SHALL have a one-to-many relationship with `ReminderList`. Each `ReminderList` MAY have an optional reference to a `ReminderListGroup`. Groups SHALL be single-level only (no nested sub-groups).

The `ReminderListGroup` model SHALL contain:
- `name: String` — the display name of the group
- `isLocked: Bool` — whether the group's identity is protected; defaults to `false`
- `sortOrder: String?` — fractional string for drag-reorder positioning
- `createdAt: Date` — creation timestamp

The `ReminderList` model SHALL gain an optional inverse relationship:
- `group: ReminderListGroup?` — nil means the list is ungrouped

#### Scenario: Group model has required properties
- **WHEN** a `ReminderListGroup` is created
- **THEN** it SHALL have a non-empty `name` and a valid `createdAt`

#### Scenario: Group is unlocked by default
- **WHEN** a `ReminderListGroup` is created without an explicit lock value
- **THEN** its `isLocked` SHALL be `false`

#### Scenario: List optionally belongs to a group
- **WHEN** a `ReminderList` is created
- **THEN** its `group` property SHALL default to `nil` (ungrouped)

#### Scenario: Groups cannot contain sub-groups
- **WHEN** any operation occurs
- **THEN** a `ReminderListGroup` SHALL NOT contain another `ReminderListGroup`

### Requirement: Default list is pinned at top

Each group's Inbox bucket SHALL appear as the first list inside its group section, before all other member lists of that group, and SHALL display an inbox tray icon. The bucket's position is established by pointer (`group.defaultList`) and initial sortOrder, not by name matching. Home SHALL render the selected area's bucket as the first section, before that area's other lists.

#### Scenario: Bucket appears first in its group
- **WHEN** the user views Home with that area selected
- **THEN** the area's Inbox bucket SHALL be the first section shown
- **AND** remaining member lists SHALL follow in their persisted order

#### Scenario: Bucket pins against name-based detection absent
- **WHEN** two or more groups each have an Inbox bucket
- **THEN** each SHALL appear first only within its own area's sections
- **AND** no name-based comparison SHALL hoist any bucket across areas

### Requirement: Drag-and-drop reorder of lists within groups

Lists within an area (including the Inbox bucket) SHALL be reorderable via drag-and-drop among themselves on Home. The bucket SHALL remain pinned first: dragging the bucket is disallowed, so it SHALL always appear above other member lists in that area. Reordering SHALL be scoped to the selected area's lists only; the app SHALL NOT offer a way to reorder lists across areas.

#### Scenario: Drag reorders lists within an area
- **WHEN** the user long-presses and drags a member list row to a new position within the same area below the bucket
- **THEN** the list SHALL appear at the dropped position
- **AND** all other member lists SHALL maintain their relative order

#### Scenario: Bucket cannot be moved from first position
- **WHEN** the user attempts to drag an area's Inbox bucket
- **THEN** the bucket SHALL remain the first section of the area
- **AND** no drag reordering SHALL move the list above it

#### Scenario: Lists cannot be dragged out of their area
- **WHEN** the user drags a list on Home
- **THEN** the list SHALL NOT be droppable into any area other than its own
- **AND** the app SHALL NOT offer an ungrouped drop target

### Requirement: New lists are ungrouped by default

After migration there SHALL be no list with `group == nil`; any list lacking a group is reparented by the reconciler. New list creation SHALL always assign the new list to an area, and SHALL offer no choice: the list SHALL be created in the currently selected area and SHALL appear as that area's last list after the bucket.

#### Scenario: Existing ungrouped list reparents
- **WHEN** the reconciler runs and a list has `group == nil`
- **THEN** the list SHALL be reparented into the Work area
- **AND** the list's tasks SHALL remain unchanged

#### Scenario: New list is created in the selected area
- **WHEN** the user creates a list with Personal selected
- **THEN** the list SHALL have `group` set to Personal
- **AND** SHALL appear as the last member list of Personal (after the bucket)

#### Scenario: List creation offers no area choice
- **WHEN** the user opens the list creation flow
- **THEN** no area or group picker SHALL be presented
- **AND** the created list's area SHALL be the selected area

## REMOVED Requirements

### Requirement: Groups display as expandable sections

**Reason**: Area `DisclosureGroup` sections with a name, chevron, and incomplete-task count are replaced by the two-pill area switcher in the navigation bar. An area is no longer a collapsible container the user opens; it is a mode the user switches into, and its lists are always visible as Home's sections.

**Migration**: The area switcher in the navigation bar shows the two areas and marks the selected one. Each area's lists appear as Home's sections scoped to the selection, each with its own collapsible header carrying the uncompleted count. Collapsed state is `@State` only and resets on launch; the previously persisted per-area expand state is no longer written.

### Requirement: Group creation via context menu

**Reason**: Exactly two areas are enforced and both are locked, so no third area can be created. The three live creation paths (list row context menu, move-to-group submenu, list creation sheet's group picker) are all removed.

**Migration**: None. Lists are still created, but only within the selected area, with no group picker.

### Requirement: Move list to group via context menu

**Reason**: A list's area is fixed at creation; there is no group picker, no "Move to Group" submenu, and no ungrouping option. Cross-*area* movement remains available, but it operates on tasks, not lists.

**Migration**: To change a task's area, reassign the task to a list in the target area via the editor's list picker or the bulk Move action. Lists themselves never change area.

### Requirement: Drag-and-drop reorder of groups

**Reason**: Areas are locked and not reorderable, and the two-area set is fixed.

**Migration**: None.

### Requirement: Drag-and-drop reorder of ungrouped lists

**Reason**: No ungrouped list can exist and no ungrouped section is rendered.

**Migration**: None.

### Requirement: Drag list between groups

**Reason**: Lists cannot change area, so there is no cross-area drop target.

**Migration**: Move individual tasks across areas instead, via the editor's list picker or the bulk Move action.

### Requirement: Empty groups are visible

**Reason**: There is no area section to render, so the "empty area" presentation (name, chevron, count of 0, empty expanded body) no longer exists. An empty area is still fully represented: its pill is present in the switcher and its bucket section renders with a count of 0.

**Migration**: An area with no lists beyond its bucket shows a single collapsed-able bucket section with a count of 0. An area with no bucket (a divergence case) is repaired by the reconciler, which creates the bucket.
