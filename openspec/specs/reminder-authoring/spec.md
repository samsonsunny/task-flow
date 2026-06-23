## ADDED Requirements

### Requirement: Reminder authoring supports rich reminder fields
The system SHALL provide reminder create and edit flows that support title, notes, URL, list assignment, tags, flag state, priority, assigned contact, image attachment, and optional schedule-related inputs.

#### Scenario: User opens reminder creation
- **WHEN** the user opens the reminder creation flow
- **THEN** the authoring surface exposes the supported reminder fields with empty or default values appropriate for a new reminder

#### Scenario: User edits an existing reminder
- **WHEN** the user opens an existing reminder for editing
- **THEN** the authoring surface shows the reminder's persisted values for every supported field

### Requirement: Reminder save state reflects meaningful user content
The system SHALL disable save when every authoring and scheduling field is empty, and SHALL enable save as soon as the reminder contains user-entered or user-selected content. When saving a task with a time set, the system SHALL schedule a local notification as a side effect.

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

### Requirement: Reminder close and discard behavior protects unsaved changes
The system SHALL close immediately when the authoring flow contains no content, and SHALL require discard confirmation before closing when unsaved content exists.

#### Scenario: Empty draft closes immediately
- **WHEN** the user taps the close action with no content in the authoring flow
- **THEN** the view dismisses without confirmation

#### Scenario: Non-empty draft requires confirmation
- **WHEN** the user taps the close action after entering reminder content without saving
- **THEN** the system shows a discard confirmation instead of dismissing immediately

#### Scenario: Discard confirmation preserves draft unless confirmed
- **WHEN** the discard confirmation is dismissed without explicit confirmation
- **THEN** the reminder draft remains intact in the authoring view

### Requirement: Reminder authoring applies default list and metadata rules
The system SHALL save reminders to the default `Reminders` list when no list is explicitly chosen, SHALL reject duplicate global tag creation, and SHALL default priority to `none` unless changed by the user.

#### Scenario: Reminder uses default list
- **WHEN** the user saves a reminder without choosing a list
- **THEN** the reminder is saved to the default `Reminders` list

#### Scenario: Duplicate tag creation is blocked
- **WHEN** the user attempts to create a tag whose normalized label already exists globally
- **THEN** the system rejects creation of the duplicate tag

#### Scenario: Priority defaults to none
- **WHEN** the user creates a new reminder without changing priority
- **THEN** the reminder is saved with priority `none`
