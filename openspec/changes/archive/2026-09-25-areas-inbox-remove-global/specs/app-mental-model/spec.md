## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Default capture target

The default neutral capture target — used when no explicit list or area is selected — SHALL be the first group's Inbox bucket (first by `sortOrder`, then `createdAt`). There is no single global "Inbox" list; "Inbox" is a per-area concept.

#### Scenario: Default capture lands in first area's bucket

- **WHEN** the user captures a task with no list or area selected
- **THEN** the task SHALL be assigned to the first group's Inbox bucket

#### Scenario: Empty store resolves to seeded Work area

- **WHEN** the user captures a task and no groups exist
- **THEN** the default Work and Personal areas SHALL be created
- **AND** the task SHALL be assigned to the Work area's Inbox bucket