## ADDED Requirements

### Requirement: Notes field uses auto-growing TextEditor
The system SHALL render the notes input in the reminder editor as a `TextEditor` that auto-grows with content height. The TextEditor SHALL expand from a minimum of one line up to a maximum height of 200 points, after which the content SHALL scroll internally within the capped frame.

#### Scenario: Empty notes shows single-line height
- **WHEN** the user opens the reminder editor with empty notes
- **THEN** the notes TextEditor renders at minimum height (approximately one line)

#### Scenario: Short notes grows to fit
- **WHEN** the user types 1-3 lines of notes
- **THEN** the TextEditor grows vertically to display all content without scrolling

#### Scenario: Long notes scrolls at cap
- **WHEN** the user enters notes content exceeding ~8-10 lines (approximately 200pt)
- **THEN** the TextEditor stops growing and scrolls internally within the 200pt frame

#### Scenario: Notes height cap on small screens
- **WHEN** the device has a small screen (e.g. iPhone SE with ~350pt usable height)
- **THEN** the notes TextEditor SHALL NOT exceed 200pt, preserving space for title, URL, and metadata fields

### Requirement: Notes field shows placeholder when empty
The system SHALL display a placeholder "Notes" in the notes TextEditor when the notes field is empty. The placeholder SHALL use the system placeholder color and match the styling of the existing TextField placeholder.

#### Scenario: Placeholder visible on empty notes
- **WHEN** the notes field is empty
- **THEN** a "Notes" placeholder is visible in the TextEditor area

#### Scenario: Placeholder disappears when content entered
- **WHEN** the user types any character into the notes field
- **THEN** the placeholder disappears and is replaced by the user's content

#### Scenario: Placeholder reappears when content cleared
- **WHEN** the user deletes all text from the notes field
- **THEN** the placeholder reappears

### Requirement: Notes TextEditor is interactive in create and edit flows
The notes TextEditor SHALL be present and interactive in both the reminder creation and reminder editing flows. The TextEditor SHALL bind bidirectionally to `draft.notes` and SHALL support standard text editing interactions (typing, selecting, pasting, scrolling).

#### Scenario: Create flow notes editing
- **WHEN** the user opens the reminder creation flow
- **THEN** the notes TextEditor is visible below the title field and accepts text input

#### Scenario: Edit flow notes editing
- **WHEN** the user opens an existing reminder for editing
- **THEN** the notes TextEditor displays the existing notes content and allows modification

#### Scenario: Notes persist on save
- **WHEN** the user enters notes and taps Save
- **THEN** the notes content is saved to the task via `Draft.notes` binding
