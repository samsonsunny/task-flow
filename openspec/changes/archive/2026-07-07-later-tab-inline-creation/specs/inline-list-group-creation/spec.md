## ADDED Requirements

### Requirement: Inline creation rows replace FAB in Later tab

The FAB overlay SHALL be removed from `ListsTabView`. Two inline creation rows SHALL be added: "+ New List" at the bottom of the Lists section and "+ New Group" at the bottom of the Groups section. Each section header SHALL also include a `+` button as a secondary creation CTA.

The Lists and Groups section headers SHALL be visible even when no lists or groups exist.

#### Scenario: FAB removed, inline row visible
- **WHEN** a user opens the Later tab
- **THEN** no floating add button is present, AND a "+ New List" row is visible at the bottom of the Lists section

#### Scenario: Inline row visible in empty Lists section
- **WHEN** a user opens the Later tab with no ungrouped lists
- **THEN** the Lists section header is still visible with a `+` button, AND the "+ New List" inline row is the only row in the section

#### Scenario: Inline row visible in empty Groups section
- **WHEN** a user opens the Later tab with no groups
- **THEN** the Groups section header is still visible with a `+` button, AND the "+ New Group" inline row is the only row in the section

#### Scenario: Section header plus button
- **WHEN** a user views the Lists or Groups section header
- **THEN** a `+` button is visible on the trailing edge of the header

### Requirement: Sheet-based list creation with optional group assignment

Tapping "+ New List" (inline row or header `+`) SHALL open a sheet with:
- A text field for the list name (auto-focused)
- A Menu picker for "Group (optional)" showing existing groups with "None" as default
- A Cancel button (leading) and Create button (trailing) in the navigation bar

Create SHALL be disabled when the name field is empty. The sheet SHALL be cancellable at any point with no side effects.

#### Scenario: Open list creation sheet
- **WHEN** a user taps the "+ New List" inline row
- **THEN** a sheet appears with a name text field (focused), a group picker set to "None", Cancel button, and Create button (disabled until name entered)

#### Scenario: Create list without group
- **WHEN** a user enters a name and taps Create with group set to "None"
- **THEN** the list is created without a group assignment, AND the sheet dismisses

#### Scenario: Create list with group assignment
- **WHEN** a user enters a name, selects a group from the picker, and taps Create
- **THEN** the list is created and assigned to the selected group, AND the sheet dismisses

#### Scenario: Cancel list creation
- **WHEN** a user taps Cancel in the list creation sheet
- **THEN** no list is created, AND the sheet dismisses

### Requirement: Sheet-based group creation with optional list assignment

Tapping "+ New Group" (inline row or header `+`) SHALL open a sheet with:
- A text field for the group name (auto-focused)
- A Menu picker for "Add List (optional)" showing ungrouped lists with "None" as default
- A Cancel button (leading) and Create button (trailing) in the navigation bar

Create SHALL be disabled when the name field is empty.

#### Scenario: Open group creation sheet
- **WHEN** a user taps the "+ New Group" inline row
- **THEN** a sheet appears with a name text field (focused), a list picker set to "None", Cancel button, and Create button (disabled until name entered)

#### Scenario: Create empty group
- **WHEN** a user enters a name and taps Create with list set to "None"
- **THEN** an empty group is created, AND the sheet dismisses

#### Scenario: Create group with list assignment
- **WHEN** a user enters a name, selects an ungrouped list from the picker, and taps Create
- **THEN** the group is created with the selected list assigned, AND the sheet dismisses

#### Scenario: No ungrouped lists hides picker
- **WHEN** a user opens group creation and no ungrouped lists exist
- **THEN** the "Add List (optional)" picker is hidden entirely

### Requirement: On-the-fly creation via mini-sheet

The association picker (group picker in list creation, list picker in group creation) SHALL include "New Group…" / "New List…" as the last option. Tapping it SHALL present a mini-sheet with a single text field and Create/Done button. On completion, the mini-sheet SHALL dismiss and the main sheet's picker SHALL auto-select the newly created entity.

#### Scenario: Create group on-the-fly during list creation
- **WHEN** a user is creating a list and taps "New Group…" in the group picker
- **THEN** a mini-sheet appears with a group name text field and Done button
- **AFTER** the user enters a name and taps Done
- **THEN** the group is created, the mini-sheet dismisses, AND the group picker in the main sheet shows the new group selected

#### Scenario: Create list on-the-fly during group creation
- **WHEN** a user is creating a group and taps "New List…" in the list picker
- **THEN** a mini-sheet appears with a list name text field and Done button
- **AFTER** the user enters a name and taps Done
- **THEN** the list is created, the mini-sheet dismisses, AND the list picker in the main sheet shows the new list selected

#### Scenario: Cancel mini-sheet
- **WHEN** a user opens a mini-sheet and taps Cancel
- **THEN** the mini-sheet dismisses, no entity is created, AND the main sheet's picker remains unchanged (default "None")

### Requirement: Association picker reflects available items

The group picker in the list creation sheet SHALL only show existing groups. The list picker in the group creation sheet SHALL only show ungrouped lists. When no items exist, the picker SHALL show only "None" and "New…".

#### Scenario: No groups available in list creation
- **WHEN** a user opens list creation with no groups in the app
- **THEN** the group picker shows "None" as the only option with "New Group…" below the separator

#### Scenario: No ungrouped lists available in group creation
- **WHEN** a user opens group creation with no ungrouped lists
- **THEN** the "Add List (optional)" picker is hidden

### Requirement: Keyboard-safe toolbar

All sheet actions (Cancel, Create, Done) SHALL be placed in the navigation bar toolbar, NOT at the bottom of the sheet. This ensures actions are accessible when the keyboard is active.

#### Scenario: Keyboard does not cover action buttons
- **WHEN** a user opens any creation sheet and the keyboard appears
- **THEN** the Cancel and Create/Done buttons remain visible in the navigation bar

#### Scenario: Create enabled on non-empty name
- **WHEN** a user types at least one character in the name field
- **THEN** the Create button becomes enabled
