## ADDED Requirements

### Requirement: List picker displays all lists organized by groups
The system SHALL present a full-screen list picker showing all available lists grouped by their `ReminderListGroup`, with the default list (Inbox) shown first, followed by grouped lists, then ungrouped lists. Lists within each group SHALL be sorted by their `sortOrder`.

#### Scenario: User opens list picker
- **WHEN** the user taps the list row in the editor
- **THEN** the system navigates to a full-screen picker showing all lists organized by groups

#### Scenario: Lists are grouped correctly
- **WHEN** the list picker is displayed
- **THEN** the default list (Inbox) appears first, followed by lists grouped under their group headers, then ungrouped lists — matching the order in the Lists tab

### Requirement: List picker supports search filtering
The system SHALL provide a search bar at the top of the list picker that filters lists by name across all groups.

#### Scenario: User searches for a list
- **WHEN** the user types in the search bar
- **THEN** the list results are filtered to show only lists whose names contain the search text, with group headers preserved for matching results

#### Scenario: Search with no results
- **WHEN** the user enters search text that matches no list names
- **THEN** the picker shows an empty state indicating no matching lists

### Requirement: Current list is pre-selected with visual indicator
The system SHALL display a checkmark next to the currently assigned list in the picker.

#### Scenario: Checkmark shows current list
- **WHEN** the user opens the list picker
- **THEN** the list currently assigned to the task (from `draft.listName`) has a checkmark indicator

### Requirement: Selecting a list updates the editor draft
The system SHALL update `draft.listName` when the user taps a list in the picker, then navigate back to the editor.

#### Scenario: User selects a different list
- **WHEN** the user taps a list in the picker that is not the current list
- **THEN** the picker dismisses, the editor's list row shows the newly selected list name, and `draft.listName` is updated

#### Scenario: User selects the same list
- **WHEN** the user taps the list that is already selected
- **THEN** the picker dismisses with no change to the draft

### Requirement: List picker defaults based on entry context
The system SHALL pre-select the list based on where the editor was opened from.

#### Scenario: Opening from a list detail view
- **WHEN** the user opens the editor from a specific list's detail view
- **THEN** the list picker defaults to that list

#### Scenario: Opening from a time-based tab
- **WHEN** the user opens the editor from Today, Tomorrow, or Upcoming
- **THEN** the list picker defaults to the Inbox (default list)
