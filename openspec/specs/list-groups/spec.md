# list-groups

## Purpose

Define the persistence and display model for organization: `ReminderListGroup` represents one of exactly two fixed domains (Work, Personal), and `ReminderList` represents an optional project/list inside a domain. This spec replaces the former user-created-group model.

## Requirements

### Requirement: ReminderListGroup represents a domain, not a user group

`ReminderListGroup` SHALL represent a top-level domain. There SHALL be exactly two valid instances: Work and Personal, identified by the canonical names in `AreaNames`. The type name is retained for schema compatibility only.

The schema SHALL remain:

- `ReminderListGroup.name: String`
- `ReminderListGroup.sortOrder: String?`
- `ReminderListGroup.createdAt: Date`
- `ReminderListGroup.lists: [ReminderList]?` (one-to-many)
- `ReminderList.group: ReminderListGroup?`

No nested domains SHALL exist. No new persisted field SHALL be added to mark a group as locked, default, or a domain; lock state and bucket identity SHALL be derived from canonical names and list membership.

#### Scenario: Schema is unchanged

- **WHEN** the two-domain model is enforced
- **THEN** no new CloudKit-mirrored property SHALL be added to `ReminderListGroup` or `ReminderList`
- **AND** existing `name`, `sortOrder`, `createdAt`, and relationship fields SHALL remain sufficient

#### Scenario: Domains are single-level

- **WHEN** any organization operation occurs
- **THEN** a `ReminderListGroup` SHALL NOT contain another `ReminderListGroup`

### Requirement: Exactly two fixed domains

The store SHALL contain exactly Work and Personal after reconciliation. Work SHALL sort before Personal. Domains SHALL NOT be user-created, renamed, deleted, or reordered.

No UI SHALL offer "New Group", "New Project" (meaning a new domain), "Rename Domain", "Delete Domain", or domain drag-reorder.

#### Scenario: Extra group is merged into Work

- **WHEN** a third `ReminderListGroup` exists
- **THEN** the reconciler SHALL reparent its surviving lists to Work
- **AND** move its bucket tasks into Work's Inbox
- **AND** delete the extra group record
- **AND** tasks SHALL NOT be deleted or have content modified

#### Scenario: Domain order is fixed

- **WHEN** the user views any surface that lists domains
- **THEN** Work SHALL appear before Personal
- **AND** the user SHALL NOT be able to reorder them

### Requirement: Lists are optional projects inside a domain

A `ReminderList` SHALL belong to exactly one domain. Each domain SHALL support unlimited lists/projects, created from within that domain's management surface. A new list SHALL be assigned to the domain that owns the surface used to create it.

There SHALL be no group picker during list creation and no ungrouped section. A list's domain SHALL be fixed at creation.

#### Scenario: New list belongs to its domain

- **WHEN** the user creates a list from Work's management surface
- **THEN** the list SHALL have `group == Work`
- **AND** it SHALL appear only in Work

#### Scenario: A domain can have no custom lists

- **WHEN** a domain has only its Inbox bucket
- **THEN** that SHALL be a valid state
- **AND** the domain SHALL remain usable for capture

#### Scenario: No ungrouped lists

- **WHEN** the app launches
- **THEN** every `ReminderList` SHALL belong to Work or Personal
- **AND** any `group == nil` list SHALL be assigned to Work by the reconciler

### Requirement: Inbox bucket is first and protected

Each domain's Inbox bucket SHALL appear first in that domain's list section, before custom lists, with an inbox tray icon. It SHALL NOT be renamable, deletable, or movable, and SHALL NOT participate in list drag-reorder.

#### Scenario: Bucket is pinned

- **WHEN** the user views Work's lists
- **THEN** Work Inbox SHALL be the first row
- **AND** custom Work lists SHALL follow in their persisted order

#### Scenario: Bucket has no destructive actions

- **WHEN** the user swipes the Work Inbox row
- **THEN** no rename, delete, or move action SHALL be offered

### Requirement: Lists reorder only within their domain

Custom lists SHALL be reorderable within their own domain using midpoint sort order. Dragging a list to another domain SHALL NOT be supported; changing a list's domain requires a future explicit product decision and data migration.

#### Scenario: Reorder stays in the domain

- **WHEN** the user reorders a Work list
- **THEN** only Work list positions SHALL change
- **AND** Personal list positions SHALL remain unchanged

#### Scenario: Cross-domain drag is rejected

- **WHEN** the user attempts to drag a list from Work to Personal
- **THEN** the list SHALL remain in Work

### Requirement: Display groups lists by domain

Any surface that shows more than one domain's lists SHALL group them under the domain names Work and Personal. It SHALL NOT show lists from both domains in a single ungrouped section.

#### Scenario: Management surface groups by domain

- **WHEN** the user opens the lists overview
- **THEN** Work's lists SHALL appear under a Work header
- **AND** Personal's lists SHALL appear under a Personal header
- **AND** there SHALL be no ungrouped section

### Requirement: Migration preserves user data

Adopting the two-domain model SHALL be additive and non-destructive. Existing lists SHALL be assigned to a domain; existing tasks SHALL remain in their lists with dates, completion, flags, notes, subtasks, and sort order intact.

#### Scenario: Legacy lists are adopted

- **WHEN** the app launches with legacy ungrouped lists
- **THEN** those lists SHALL be assigned to Work
- **AND** their tasks SHALL remain unchanged

#### Scenario: Merged lists keep their tasks

- **WHEN** a list is reparented from an extra group into Work
- **THEN** every task in that list SHALL keep the same list object
- **AND** no task content SHALL change
