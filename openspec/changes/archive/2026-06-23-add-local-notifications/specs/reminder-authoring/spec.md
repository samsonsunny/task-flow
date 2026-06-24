## MODIFIED Requirements

### Requirement: Reminder save state reflects meaningful user content
The system SHALL disable save when every authoring and scheduling field is empty, and SHALL enable save as soon as the reminder contains user-entered or user-selected content. Additionally, when saving a task with a time set, the system SHALL schedule a local notification as a side effect.

#### Scenario: Empty reminder cannot be saved
- **WHEN** the user opens a new reminder and leaves all fields empty
- **THEN** the save action remains disabled

#### Scenario: Entered content enables save
- **WHEN** the user enters content into any supported reminder field
- **THEN** the save action becomes enabled

#### Scenario: Clearing all content disables save again
- **WHEN** the user removes all previously entered reminder content
- **THEN** the save action returns to the disabled state

#### Scenario: Save with time set schedules notification
- **WHEN** the user saves a reminder with a time set and the `dueDate` is in the future
- **THEN** the system saves the reminder AND schedules a local notification for the `dueDate`
