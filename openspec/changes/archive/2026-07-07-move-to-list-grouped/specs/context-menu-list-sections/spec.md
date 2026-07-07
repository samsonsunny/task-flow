## ADDED Requirements

### Requirement: Lists are organized into sections by group

The "Move to List" context menu submenu SHALL organize lists into sections based on the existing `ReminderListGroup` model. The menu SHALL display lists in the following order:

1. Default list ("Inbox") — alone in its own section with no header
2. Grouped lists — each `ReminderListGroup` is a `Section` with the group name as its header
3. Ungrouped lists — remaining lists with no `group` reference, in a section with no header

Lists that are in the same group as the task's current list SHALL still appear (the task is moved within its group).

#### Scenario: Group-aware menu structure
- **WHEN** the user opens the context menu on a task
- **AND** selects "Move to List"
- **THEN** the submenu SHALL display the default list first (if applicable)
- **AND** SHALL display each `ReminderListGroup` as a section with the group name as header
- **AND** SHALL display ungrouped lists after grouped sections

#### Scenario: No groups exist — flat list
- **WHEN** no `ReminderListGroup` objects exist
- **THEN** all lists SHALL appear in a single flat section (no headers)
- **AND** the menu SHALL behave identically to the current implementation

### Requirement: Default list is pinned at top

The default list (with name matching `ReminderDefaults.defaultListName`) SHALL always appear as the first item in the "Move to List" submenu, in its own section with no header. It SHALL NOT be placed inside any group section.

#### Scenario: Default list always first
- **WHEN** the context menu "Move to List" submenu is shown
- **THEN** the default list SHALL be the first item regardless of its group assignment or sort order

### Requirement: ViewModel provides structured list sections

Each ViewModel that provides lists for the context menu SHALL expose a `listSections` computed property returning an array of `ListSection` values. A `ListSection` SHALL contain:
- An optional `title` string (nil means no section header)
- An array of `ReminderList` items

#### Scenario: ListSection type is defined
- **WHEN** the ViewModel provides `listSections`
- **THEN** each `ListSection` SHALL contain an optional `title` and an array of `ReminderList` lists
- **AND** the total count of lists across all sections SHALL equal the count of all lists except the task's current list

### Requirement: Context menu renders sections

The `TaskRowView` SHALL render the "Move to List" submenu using SwiftUI `Section` views. Each `Section` SHALL be created from a `ListSection`:
- If the section's `title` is non-nil, it SHALL be passed as the `Section` header
- If nil, no header text SHALL be displayed (the section separator line still renders)

#### Scenario: Section rendering
- **WHEN** "Move to List" has multiple `ListSection` values
- **THEN** each section SHALL be rendered as a SwiftUI `Section`
- **AND** each `Section` SHALL contain a `ForEach` over its lists

### Requirement: Current list is excluded

The task's current list SHALL NOT appear in the "Move to List" submenu. Each ViewModel SHALL filter out the current list when constructing `listSections`.

#### Scenario: Current list excluded
- **WHEN** constructing `listSections`
- **THEN** the list the task currently belongs to SHALL be excluded from all sections
