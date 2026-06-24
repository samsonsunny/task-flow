## ADDED Requirements

### Requirement: User can rename any unprotected list via context menu

The system SHALL allow users to rename any list that is not the protected "Reminders" list. Renaming SHALL be initiated via a context menu on the list row in `ListsTabView`. The protected "Reminders" list SHALL NOT show a rename option in its context menu.

#### Scenario: Rename a custom list
- **WHEN** the user long-presses a list row (that is not "Reminders") in `ListsTabView`
- **THEN** the context menu SHALL display a "Rename" option

#### Scenario: Protected list has no rename option
- **WHEN** the user long-presses the "Reminders" list row in `ListsTabView`
- **THEN** the context menu SHALL NOT include a "Rename" option

### Requirement: Rename uses an alert with a text field

When the user taps "Rename" from the context menu, the system SHALL present an alert containing a text field pre-filled with the current list name. The user can edit the name and confirm or cancel.

#### Scenario: Rename with valid name
- **WHEN** the user edits the name in the alert text field and confirms
- **THEN** the list's `name` field SHALL be updated to the new value
- **AND** the new name SHALL be reflected immediately in `ListsTabView` and `ListDetailView` navigation titles

#### Scenario: Rename with empty name is rejected
- **WHEN** the user clears the name field and confirms
- **THEN** the system SHALL NOT update the list name
- **AND** the alert SHALL remain visible or dismiss without changes

#### Scenario: Cancel rename
- **WHEN** the user taps Cancel in the rename alert
- **THEN** the list name SHALL remain unchanged
