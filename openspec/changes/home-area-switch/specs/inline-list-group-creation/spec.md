## Purpose

Define the inline "Create New Group" flow that creates a group (with its Inbox bucket) and moves the source list into it.

## MODIFIED Requirements

### Requirement: Sheet-based list creation with optional group assignment

Tapping the list-creation control SHALL open a sheet with:
- A text field for the list name (auto-focused)
- A Cancel button (leading) and Create button (trailing) in the navigation bar

The sheet SHALL NOT contain an area or group picker. The new list SHALL be created in the currently selected area, which the sheet SHALL state in its own copy (e.g. "Creates a list in Work") so the destination is never ambiguous. Create SHALL be disabled when the name field is empty. The sheet SHALL be cancellable at any point with no side effects.

#### Scenario: Open list creation sheet
- **WHEN** a user taps the list-creation control
- **THEN** a sheet appears with a name text field (focused), a Cancel button, and a Create button (disabled until a name is entered)
- **AND** no group picker is present

#### Scenario: Sheet names the destination area
- **WHEN** the user opens list creation with Personal selected
- **THEN** the sheet SHALL indicate that the list will be created in Personal

#### Scenario: Create list
- **WHEN** the user enters a name and taps Create
- **THEN** the list SHALL be created in the selected area
- **AND** the sheet SHALL dismiss
- **AND** the list SHALL appear as that area's last section on Home

#### Scenario: Cancel list creation
- **WHEN** the user taps Cancel in the list creation sheet
- **THEN** no list SHALL be created
- **AND** the sheet SHALL dismiss

### Requirement: Keyboard-safe toolbar

All sheet actions (Cancel, Create) SHALL be placed in the navigation bar toolbar, NOT at the bottom of the sheet. This ensures actions are accessible when the keyboard is active.

#### Scenario: Keyboard does not cover action buttons
- **WHEN** a user opens the list creation sheet and the keyboard appears
- **THEN** the Cancel and Create buttons remain visible in the navigation bar

#### Scenario: Create enabled on non-empty name
- **WHEN** a user types at least one character in the name field
- **THEN** the Create button becomes enabled

## REMOVED Requirements

### Requirement: Inline creation rows replace FAB in Later tab

**Reason**: There is no Later tab and no floating add button. Home's header carries no `+`, and Home's only creation control is the capture bar, which creates tasks rather than lists. Section headers on Home are collapsible list headers with no secondary creation button, because the `+` next to the capture bar is precisely the affordance that made the capture bar read as list creation. List creation moves to the Home overflow menu.

**Migration**: Create a list from Home's overflow menu, or from list detail. The new list always lands in the selected area and is announced as such in the sheet.

### Requirement: Sheet-based group creation with optional list assignment

**Reason**: Exactly two locked areas exist and all group-creation UI is removed, so this sheet has no trigger and no valid target.

**Migration**: None. Areas are fixed at Work and Personal and are created only by the reconciler when the store is empty.

### Requirement: On-the-fly creation via mini-sheet

**Reason**: The mini-sheet existed solely to create a group mid-list-creation. With no group picker and no group creation, `MiniCreationSheet` has no call site and is removed.

**Migration**: None.

### Requirement: Association picker reflects available items

**Reason**: This requirement governs the group picker in list creation and the list picker in group creation. Both pickers are removed.

**Migration**: None. Area assignment is implicit in the selected area and stated in the list creation sheet's copy.
