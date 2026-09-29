# app-mental-model

## Purpose

Define the two-axis product mental model (attention vs. home) that the app’s navigation, organization, and capture behavior build on.
## Requirements
### Requirement: Two axes
The app SHALL organize navigation and task visibility around two orthogonal axes: an attention axis driven by due date, and a home axis driven by list membership. A task SHALL always belong to a list in the home axis; it SHALL surface in a time tab only while it carries a due date. Clearing the due date SHALL return the task to Later-only visibility.

#### Scenario: A task lives in both axes simultaneously
- **WHEN** a user creates a task inside a list and gives it a due date
- **THEN** the task appears in that list's detail (home axis) and in the matching time tab (attention axis)

#### Scenario: Clearing the due date returns a task to Later only
- **WHEN** the user removes a task's due date
- **THEN** the task SHALL no longer appear in any time tab
- **AND** it SHALL remain in its list

### Requirement: Navigation
The app SHALL expose a single 4-tab `TabView` as its only navigation surface, with no separate sidebar surface.

| Tab | Purpose | Content |
|---|---|---|
| Today | Attention now | Tasks due today (dated subtasks included, flat) |
| Tomorrow | Attention next | Tasks due tomorrow (dated subtasks included, flat) |
| Upcoming | Coming in future | Tasks due D+2 onward (dated subtasks included, flat) |
| Later | Permanent home | Groups (areas) and lists — the organizational structure |

#### Scenario: Time tabs split the attention axis
- **WHEN** the user opens Today, Tomorrow, or Upcoming
- **THEN** each tab SHALL show only the tasks whose due date falls in that tab's range

#### Scenario: Later holds the home axis
- **WHEN** the user opens the Later tab
- **THEN** the app SHALL show the user's groups (areas) and their lists

### Requirement: Later tab

"Later" is **not** a someday bucket. It is the permanent organizational home of a user's tasks, lists, and projects, independent of due dates. Later SHALL contain `ReminderListGroup` (areas, grouped as expandable sections) and `ReminderList` items. Every list SHALL belong to a group/area — there SHALL be no ungrouped section and no standalone global list. Each group/area SHALL contain an Inbox bucket: a protected first list (named "Inbox", tray icon) that is the area's neutral landing zone for new/uncategorized tasks. Tapping a list SHALL push `ListDetailView` onto Later's `NavigationStack`.

#### Scenario: Every list belongs to an area

- **WHEN** the user views the Later tab after migration
- **THEN** every visible list SHALL appear within a group/area section
- **AND** no global "Inbox" list SHALL appear outside a group

#### Scenario: Each area shows its own Inbox bucket

- **WHEN** the user expands a group/area in Later
- **THEN** the area's Inbox bucket SHALL be the first list shown
- **AND** the bucket SHALL carry an inbox tray icon

### Requirement: Deadline submenu
The task context menu SHALL expose all due-date actions inside a single "Deadline" submenu in `TaskRowView`: "None" (always listed, no leading icon), a divider, then Today, Tomorrow, This Weekend, Next Week, and Custom…. Each preset SHALL carry a leading calendar icon with its target day-of-month. The submenu SHALL be state-aware via an active-item checkmark: "None" SHALL be ticked when the task has no date, the matching preset when the due date equals its target day, and Custom… for any other date. No due-date option SHALL be hidden.

#### Scenario: Active due-date option is checked
- **WHEN** the user opens the Deadline submenu on a task due today
- **THEN** the "Today" preset SHALL show an active checkmark

#### Scenario: Selecting None clears the due date
- **WHEN** the user selects "None" from the Deadline submenu
- **THEN** the task's due date SHALL be cleared
- **AND** the task SHALL disappear from time tabs while remaining in its list

### Requirement: Default capture target

The default neutral capture target — used when no explicit list or area is selected — SHALL be the first group's Inbox bucket (first by `sortOrder`, then `createdAt`). There is no single global "Inbox" list; "Inbox" is a per-area concept.

#### Scenario: Default capture lands in first area's bucket

- **WHEN** the user captures a task with no list or area selected
- **THEN** the task SHALL be assigned to the first group's Inbox bucket

#### Scenario: Empty store resolves to seeded Work area

- **WHEN** the user captures a task and no groups exist
- **THEN** the default Work and Personal areas SHALL be created
- **AND** the task SHALL be assigned to the Work area's Inbox bucket

