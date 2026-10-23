# inline-list-group-creation

## Purpose

Define list creation inside a fixed domain. The former user-created "group" flow is retired: Work and Personal are permanent, and users add projects/lists only within one of them.

## Requirements

### Requirement: List creation is scoped to a domain

Every list-creation entry point SHALL be opened from a specific domain and SHALL create the list inside that domain. There SHALL be no domain picker, no "None"/ungrouped option, and no fallback to a different domain.

#### Scenario: Create a list in Work

- **WHEN** the user taps "New List" while managing Work
- **THEN** a sheet SHALL appear with a focused name field
- **AND** creating it SHALL assign the list to Work

#### Scenario: Create a list in Personal

- **WHEN** the user taps "New List" while managing Personal
- **THEN** creating it SHALL assign the list to Personal

#### Scenario: No domain context

- **WHEN** a creation entry point has no domain context
- **THEN** the app SHALL require the user to enter a domain's list surface first
- **AND** SHALL NOT create an ungrouped list

### Requirement: List creation sheet

The sheet SHALL contain:

- a text field for the list name, auto-focused
- Cancel and Create actions in the navigation bar
- Create disabled while the trimmed name is empty

#### Scenario: Create with a valid name

- **WHEN** the user enters a non-empty name and taps Create
- **THEN** the list SHALL be inserted in the active domain
- **AND** the sheet SHALL dismiss

#### Scenario: Empty name is rejected

- **WHEN** the name field is empty or whitespace
- **THEN** Create SHALL be disabled
- **AND** no list SHALL be created

#### Scenario: Cancel

- **WHEN** the user taps Cancel
- **THEN** no list SHALL be created
- **AND** the sheet SHALL dismiss

### Requirement: No user-created domains

There SHALL be no UI to create a new `ReminderListGroup`, no "New Group" inline row, and no "New Project" action that creates a group. The only valid domains are Work and Personal.

#### Scenario: No create-domain affordance

- **WHEN** the user opens any management surface
- **THEN** no action SHALL create a third domain

#### Scenario: No group picker

- **WHEN** the user creates a list
- **THEN** the sheet SHALL NOT show a group/domain picker

### Requirement: Keyboard-safe actions

Cancel and Create SHALL remain in the navigation bar while the keyboard is visible.

#### Scenario: Keyboard does not cover actions

- **WHEN** the keyboard is shown in the creation sheet
- **THEN** Cancel and Create SHALL remain visible
