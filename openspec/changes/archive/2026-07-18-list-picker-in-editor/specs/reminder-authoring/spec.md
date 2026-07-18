## MODIFIED Requirements

### Requirement: Reminder authoring supports rich reminder fields
The system SHALL provide reminder create and edit flows that support title, notes, URL, list assignment, tags, flag state, priority, assigned contact, image attachment, and optional schedule-related inputs. List assignment SHALL be exposed via a tappable row that navigates to a full-screen list picker.

#### Scenario: User opens reminder creation
- **WHEN** the user opens the reminder creation flow
- **THEN** the authoring surface exposes the supported reminder fields with empty or default values appropriate for a new reminder, including a list row showing the default list

#### Scenario: User edits an existing reminder
- **WHEN** the user opens an existing reminder for editing
- **THEN** the authoring surface shows the reminder's persisted values for every supported field, including the current list assignment in the list row

#### Scenario: User changes list assignment
- **WHEN** the user taps the list row and selects a different list
- **THEN** the editor's list row updates to show the selected list name, and `draft.listName` reflects the new selection

### Requirement: Reminder authoring applies default list and metadata rules
The system SHALL save reminders to the default `Reminders` list when no list is explicitly chosen, SHALL reject duplicate global tag creation, and SHALL default priority to `none` unless changed by the user.

#### Scenario: Reminder uses default list
- **WHEN** the user saves a reminder without choosing a list
- **THEN** the reminder is saved to the default `Reminders` list

#### Scenario: User explicitly selects a list
- **WHEN** the user selects a list from the list picker and saves the reminder
- **THEN** the reminder is saved to the selected list

#### Scenario: Duplicate tag creation is blocked
- **WHEN** the user attempts to create a tag whose normalized label already exists globally
- **THEN** the system rejects creation of the duplicate tag

#### Scenario: Priority defaults to none
- **WHEN** the user creates a new reminder without changing priority
- **THEN** the reminder is saved with priority `none`
