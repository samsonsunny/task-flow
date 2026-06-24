## ADDED Requirements

### Requirement: Lists are reorderable via drag in ListsTabView

The system SHALL allow users to reorder all lists (including "Reminders") in `ListsTabView` by dragging rows. The reordered position SHALL persist across app restarts.

#### Scenario: Drag reorders a single list
- **WHEN** the user long-presses and drags a list row to a new position in `ListsTabView`
- **THEN** the list SHALL appear at the dropped position
- **AND** all other lists SHALL remain in their relative positions
- **AND** the new order SHALL persist after relaunching the app

#### Scenario: "Reminders" list is reorderable
- **WHEN** the user drags the "Reminders" list to a new position
- **THEN** "Reminders" SHALL appear at the dropped position
- **AND** is NOT pinned to the top of the list

### Requirement: Sort order uses fractional string encoding

The system SHALL store each list's position as a `String?` sortOrder using the same lexicographic midpoint algorithm used for task ordering. Only the dragged list's sortOrder SHALL be updated per drag operation.

#### Scenario: Single drag updates one record
- **WHEN** a list is dragged to a new position between two other lists
- **THEN** the system SHALL update only that list's `sortOrder` in the database
- **AND** SHALL NOT modify `sortOrder` on any other list

### Requirement: New lists append to end

When a list is created, the system SHALL assign it a sortOrder that places it after all existing lists.

#### Scenario: New list appears at bottom
- **WHEN** a user creates a new list
- **THEN** the list SHALL appear as the last item in `ListsTabView`
- **AND** all existing list positions SHALL remain unchanged

### Requirement: Existing lists backfilled on migration

On first launch after the update, all existing `ReminderList` entries without a `sortOrder` SHALL receive an initial sortOrder based on their current display order ("Reminders" first, then alphabetical by name).

#### Scenario: Existing lists get sequential sortOrder
- **WHEN** the app launches after the update
- **THEN** every existing `ReminderList` SHALL have a non-nil `sortOrder`
- **AND** sortOrder values SHALL respect the original display order (Reminders first, then alphabetical)
