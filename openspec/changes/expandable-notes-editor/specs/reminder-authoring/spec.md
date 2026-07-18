## MODIFIED Requirements

### Requirement: Reminder authoring supports rich reminder fields
The system SHALL provide reminder create and edit flows that support title, notes, URL, list assignment, tags, flag state, priority, assigned contact, image attachment, and optional schedule-related inputs. The notes field SHALL use an auto-growing `TextEditor` with a 200-point height cap and placeholder overlay, replacing the previous `TextField(axis: .vertical)` with `.lineLimit(1...4)`.

#### Scenario: User opens reminder creation
- **WHEN** the user opens the reminder creation flow
- **THEN** the authoring surface exposes the supported reminder fields with empty or default values appropriate for a new reminder
- **AND** the notes field renders as an auto-growing TextEditor with placeholder "Notes"

#### Scenario: User edits an existing reminder
- **WHEN** the user opens an existing reminder for editing
- **THEN** the authoring surface shows the reminder's persisted values for every supported field
- **AND** the notes field renders as an auto-growing TextEditor displaying the existing notes content
