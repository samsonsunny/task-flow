# list-picker

## Purpose

Define the list picker used when assigning or moving a task to a project/list, with lists grouped by their Work or Personal domain.

## Requirements

### Requirement: List picker displays all lists grouped by domain

The system SHALL present a full-screen list picker showing all available lists grouped under their domain: Work and Personal. Each domain's Inbox SHALL appear first in its section, followed by that domain's custom lists in sort order. There SHALL be no ungrouped section.

#### Scenario: User opens the list picker

- **WHEN** the user taps the list row in the editor
- **THEN** the picker SHALL show Work and Personal sections
- **AND** each section SHALL list its Inbox first

#### Scenario: Lists match domain order

- **WHEN** the picker is displayed
- **THEN** Work lists SHALL appear under Work
- **AND** Personal lists SHALL appear under Personal
- **AND** no list SHALL appear outside a domain

### Requirement: List picker supports search filtering

The system SHALL provide a search bar that filters lists by name across both domains.

#### Scenario: User searches for a list

- **WHEN** the user types in the search bar
- **THEN** only lists whose names contain the text SHALL be shown
- **AND** matching results SHALL keep their domain headers

#### Scenario: Search has no results

- **WHEN** the search matches no list names
- **THEN** the picker SHALL show an empty state

### Requirement: Current list is pre-selected with a visual indicator

The list currently assigned to the task SHALL display a checkmark.

#### Scenario: Checkmark shows current list

- **WHEN** the user opens the picker for an existing task
- **THEN** the task's current list SHALL show a checkmark

### Requirement: Selecting a list updates the editor draft

Tapping a list SHALL update the editor's selected list and dismiss the picker.

#### Scenario: Select a different list

- **WHEN** the user taps a list other than the current one
- **THEN** the draft's list SHALL update
- **AND** the editor SHALL show the new list name

#### Scenario: Select the same list

- **WHEN** the user taps the current list
- **THEN** the picker SHALL dismiss with no change

### Requirement: Picker defaults from entry context

The picker SHALL pre-select a target based on where the editor was opened:

- from a specific list → that list
- from Work → Work Inbox
- from Personal → Personal Inbox
- from Today or another context without a domain/list → Work Inbox
- from a board column → that column's list

#### Scenario: Opening from a list detail view

- **WHEN** the editor opens from a specific list
- **THEN** that list SHALL be selected

#### Scenario: Opening from Work

- **WHEN** the editor opens from Work
- **THEN** Work Inbox SHALL be selected

#### Scenario: Opening from Personal

- **WHEN** the editor opens from Personal
- **THEN** Personal Inbox SHALL be selected

#### Scenario: Opening from Today

- **WHEN** the editor opens from Today without another context
- **THEN** Work Inbox SHALL be selected
