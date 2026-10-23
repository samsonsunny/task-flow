# app-mental-model

## Purpose

Define the canonical product model that all navigation, organization, capture, and editor behavior builds on: exactly **two permanent domains** (Work and Personal) with optional projects/lists inside them, plus a cross-domain **Today** view. This spec is binding. A feature that introduces a third domain, turns a project/list into a top-level tab, or adds a second model for domains is out of policy.

## Requirements

### Requirement: Exactly two permanent domains

The app SHALL have exactly two domains: **Work** and **Personal**. They SHALL be represented by the existing `ReminderListGroup` model for persistence compatibility, but "group" is a legacy type name — in product language and new code they are domains.

Work and Personal SHALL:

- exist on every install, including an empty store
- be seeded and repaired by the reconciler on launch
- keep the canonical stored names `Work` and `Personal` (`AreaNames.work`, `AreaNames.personal`)
- NOT be creatable, renamable, deletable, or reorderable through any UI

No third domain SHALL exist. Any additional `ReminderListGroup` is invalid legacy data and SHALL be folded into Work by the reconciler (see `areas-inbox`).

#### Scenario: Fresh install has both domains

- **WHEN** the app launches with an empty store
- **THEN** Work and Personal SHALL exist
- **AND** each SHALL own exactly one Inbox list

#### Scenario: Extra group is folded into Work

- **WHEN** the store contains a `ReminderListGroup` that is neither Work nor Personal
- **THEN** the reconciler SHALL preserve that group's lists and tasks under Work
- **AND** the extra group record SHALL be removed
- **AND** no third domain or third tab SHALL appear

#### Scenario: Domains cannot be edited

- **WHEN** the user views or swipes a domain row in a management surface
- **THEN** no create, rename, delete, or reorder action for the domain SHALL be offered

### Requirement: Projects and lists live inside a domain

Every `ReminderList` SHALL belong to exactly one domain. A list SHALL NOT be ungrouped in a valid store, and there SHALL be no global list outside Work or Personal. `ReminderList.group == nil` is invalid state that the reconciler repairs by assigning the list to Work.

Projects/lists are optional, user-created organization *inside* a domain. There SHALL be no limit on how many a user creates, and creating them SHALL NOT change the root navigation. A list's domain SHALL be fixed at creation; ordinary list management SHALL NOT move a list between Work and Personal.

#### Scenario: User creates lists inside Personal

- **WHEN** the user creates a list from the Personal domain's list surface
- **THEN** the list SHALL belong to Personal
- **AND** its tasks SHALL appear in the Personal tab

#### Scenario: Many projects do not add tabs

- **WHEN** the user creates ten projects/lists across Work and Personal
- **THEN** the root tab bar SHALL still show exactly Today, Work, Personal, and More
- **AND** every project/list SHALL remain reachable from its domain

#### Scenario: Ungrouped list is repaired

- **WHEN** a `ReminderList` exists with `group == nil`
- **THEN** the reconciler SHALL assign it to Work
- **AND** its tasks SHALL remain in the list, unmodified

#### Scenario: Deleting a list never orphans tasks

- **WHEN** the user deletes a project/list
- **THEN** the user SHALL choose to move its tasks to the domain's Inbox or delete them with the list
- **AND** no task SHALL be left without a list

### Requirement: Every domain owns one Inbox bucket

Each domain SHALL own exactly one Inbox bucket — a real, visible list that is the domain's neutral landing zone for tasks created without a specific project/list. The bucket SHALL be the first list shown in its domain and SHALL display the inbox tray icon.

Bucket identity is derived from the owning domain plus the canonical `Inbox` name; it SHALL NOT be persisted as a new relationship or column. The CloudKit production schema is sealed, and adding a pointer would break sync export. Work's and Personal's buckets SHALL be protected from rename, delete, and cross-domain moves.

#### Scenario: New task without a project lands in Inbox

- **WHEN** the user creates a task in Work without choosing a project/list
- **THEN** the task SHALL be assigned to Work's Inbox bucket
- **AND** the task SHALL belong to the Work domain

#### Scenario: Personal capture does not cross domains

- **WHEN** the user creates a task in Personal without choosing a project/list
- **THEN** the task SHALL be assigned to Personal's Inbox bucket
- **AND** it SHALL NOT be assigned to Work's bucket

#### Scenario: Default capture when no domain is active

- **WHEN** the user captures from a surface with no domain or list context
- **THEN** the task SHALL default to Work's Inbox bucket

### Requirement: Today is cross-domain

Today SHALL show the attention set across both domains: incomplete tasks that are overdue or due today, with no requirement to switch domains. Rows SHALL identify the owning domain so mixed lists remain legible. Filtering Today by domain MAY be offered, but the default SHALL be all domains.

There SHALL NOT be separate Tomorrow or Upcoming tabs. Future and undated tasks remain in their domain and project/list until they become due; they do not require a separate home tab.

#### Scenario: Tasks from both domains appear together

- **WHEN** a Work task and a Personal task are both due today
- **THEN** both SHALL appear in Today
- **AND** each row SHALL indicate its domain

#### Scenario: Future task is not in Today

- **WHEN** a task is due tomorrow or has no due date
- **THEN** it SHALL NOT appear in Today
- **AND** it SHALL remain visible in its Work or Personal domain

### Requirement: Root navigation is fixed

The root navigation SHALL be a four-tab `TabView`: **Today**, **Work**, **Personal**, and **More**. The tab bar SHALL NOT include a tab per project, a user-created domain tab, or legacy time tabs (`Later`, `Tomorrow`, `Upcoming`).

Projects/lists SHALL be reached from within their domain's management surface, never by adding a permanent root tab.

#### Scenario: Project is not promoted to a tab

- **WHEN** a user has a large project in Personal
- **THEN** the project SHALL remain a list inside Personal
- **AND** the root tab bar SHALL remain unchanged

### Requirement: Customer-facing terminology

The product term for the second domain SHALL be **Personal**. "Home" is a retired display alias and SHALL NOT be introduced in new copy, specs, or code. Stored values remain `Work` and `Personal` for data compatibility.

"Domain" refers to Work/Personal. "Project" or "list" refers to a `ReminderList` inside a domain. Documentation and UI SHALL NOT call a domain a project, and SHALL NOT call a project a domain.

#### Scenario: Domain label is Personal

- **WHEN** any surface displays the second domain's name
- **THEN** it SHALL read "Personal", not "Home"

### Requirement: Legacy compatibility and data safety

The two-domain model SHALL be implemented with the existing CloudKit-mirrored models. No new persisted field or relationship SHALL be added to distinguish domains from projects; the distinction is `ReminderListGroup` (domain) versus `ReminderList` (project/list) with canonical names.

Migrations and reconciliation SHALL preserve user data. Extra domains may be folded into Work, but their lists and tasks SHALL survive. No `TaskItem` SHALL be deleted or have its dates, flags, notes, completion state, or ordering reset as part of enforcing the two-domain model.

#### Scenario: Divergent build's data survives

- **WHEN** data created by a build with extra groups syncs down
- **THEN** the extra groups' lists SHALL become Work lists
- **AND** tasks in their buckets SHALL be repointed to Work's Inbox
- **AND** all task content SHALL be preserved

#### Scenario: No schema change for the model

- **WHEN** this model is enforced
- **THEN** no CloudKit-mirrored model SHALL gain a domain/project field
- **AND** no migration plan stage SHALL be required for the two-domain rules

### Requirement: Feature review guardrail

Before adding navigation, capture, or organization behavior, a feature MUST answer both questions:

1. **Which domain does this belong to?** Work, Personal, or both (Today only).
2. **Does it add a top-level destination?** If the answer is a project/list, the feature is out of policy.

#### Scenario: Proposal adds a project tab

- **WHEN** a proposal would add one tab per project or let users create another top-level domain
- **THEN** the proposal SHALL be rejected or redesigned to live inside Work/Personal
