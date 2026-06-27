## ADDED Requirements

### Requirement: ViewModel owns list CRUD
The ViewModel SHALL handle list creation, rename, and deletion including the delete cascade with two options (move tasks to default list, or delete all tasks).

#### Scenario: Create list inserts new list
- **WHEN** `createList(name:)` is called with non-empty name
- **THEN** a new `ReminderList` SHALL be inserted into the model context with sort order at the end

#### Scenario: Rename list updates name
- **WHEN** `renameList(_:to:)` is called with non-empty trimmed name
- **THEN** the list's name SHALL be updated

#### Scenario: Delete list with move re-parents tasks
- **WHEN** `deleteList(_:moveTasksToDefault:)` is called with `moveTasksToDefault: true`
- **THEN** all tasks in the list SHALL be re-parented to the default "Reminders" list, then the list SHALL be deleted

#### Scenario: Delete list with cascade deletes all tasks
- **WHEN** `deleteList(_:moveTasksToDefault:)` is called with `moveTasksToDefault: false`
- **THEN** all tasks in the list SHALL be deleted (with notification cancellation), then the list SHALL be deleted

### Requirement: ViewModel owns group CRUD
The ViewModel SHALL handle group creation, rename, and deletion including cascading deletion of all lists and tasks within a group.

#### Scenario: Create group with optional source list
- **WHEN** `createGroup(name:sourceList:)` is called
- **THEN** a new `ReminderListGroup` SHALL be inserted, and if a source list is provided, it SHALL be assigned to the new group

### Requirement: ViewModel owns list reorder
The ViewModel SHALL handle drag-drop reorder of lists within ungrouped and grouped sections using the midpoint/widen algorithm.

#### Scenario: Reorder within ungrouped section
- **WHEN** `moveLists(fromOffsets:toOffset:in:)` is called
- **THEN** sort orders SHALL be reassigned using the midpoint algorithm

### Requirement: ViewModel owns group expand/collapse
The ViewModel SHALL persist group expansion state to UserDefaults and expose toggle and query methods.

#### Scenario: Group state persisted
- **WHEN** a group is expanded or collapsed
- **THEN** the expansion state SHALL be saved to UserDefaults and restored on next app launch

### Requirement: ViewModel owns group assignment
The ViewModel SHALL support moving a list to a group or removing it from a group.

#### Scenario: Move list to group
- **WHEN** a list's group property is set to a group
- **THEN** the change SHALL be persisted via model context save

### Requirement: ViewModel provides dialog presentation state
The ViewModel SHALL expose all boolean and optional properties needed for alert/sheet presentation in the view.

#### Scenario: Dialog states drive view presentation
- **WHEN** `isCreatingList` is true
- **THEN** the view SHALL present the "New List" alert
