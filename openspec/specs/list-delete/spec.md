## ADDED Requirements

### Requirement: User can delete any unprotected list via context menu

The system SHALL allow users to delete any list that is not the protected "Reminders" list. Deletion SHALL be initiated via a context menu on the list row in `ListsTabView`. The protected "Reminders" list SHALL NOT show a delete option in its context menu.

#### Scenario: Delete option appears in context menu
- **WHEN** the user long-presses a list row (that is not "Reminders") in `ListsTabView`
- **THEN** the context menu SHALL display a "Delete List" option

#### Scenario: Protected list has no delete option
- **WHEN** the user long-presses the "Reminders" list row in `ListsTabView`
- **THEN** the context menu SHALL NOT include a "Delete List" option

### Requirement: Delete shows confirmation with two cascade options

When the user taps "Delete List", the system SHALL present a confirmation alert with two explicit choices:
1. "Move tasks to Reminders" — re-parents all tasks to the default "Reminders" list, then deletes the list
2. "Delete All Tasks" — deletes all tasks in the list (cascade), then deletes the list

"Move tasks to Reminders" SHALL be the default (non-destructive) option. "Delete All Tasks" SHALL be visually styled as destructive.

#### Scenario: Move tasks to Reminders on delete
- **WHEN** the user taps "Move tasks to Reminders" in the delete confirmation
- **THEN** every task in the deleted list SHALL have its `reminderList` set to the "Reminders" list
- **AND** the list SHALL be deleted from the model context
- **AND** the tasks SHALL remain accessible in "Reminders" and any other views that reference them

#### Scenario: Cascade delete all tasks
- **WHEN** the user taps "Delete All Tasks" in the delete confirmation
- **THEN** every task in the deleted list SHALL be deleted from the model context
- **AND** the list SHALL be deleted from the model context
- **AND** all associated notifications for those tasks SHALL be cancelled

#### Scenario: Cancel delete
- **WHEN** the user taps Cancel in the delete confirmation
- **THEN** the list and its tasks SHALL remain unchanged

#### Scenario: Delete an empty list
- **WHEN** the user deletes a list that contains no tasks
- **THEN** the confirmation alert SHALL still appear with both options
- **AND** both options SHALL produce the same result: the list is deleted, no tasks are affected
