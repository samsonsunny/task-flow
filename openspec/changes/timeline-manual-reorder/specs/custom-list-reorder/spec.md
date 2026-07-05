## MODIFIED Requirements

### Requirement: Tasks are reorderable via drag in custom lists

The system SHALL allow users to reorder tasks within any custom task list by dragging rows. The reordered position SHALL persist across app restarts. Task order in timeline views is covered by the `timeline-reorder` spec.

#### Scenario: Drag reorders a single task in a custom list
- **WHEN** the user long-presses and drags a task row to a new position within the same custom list
- **THEN** the task SHALL appear at the dropped position
- **AND** all other tasks SHALL remain in their relative positions
- **AND** the new order SHALL persist after relaunching the app

#### Scenario: Multi-select drag reorders multiple tasks
- **WHEN** the user selects multiple tasks and drags them to a new position
- **THEN** the selected tasks SHALL appear at the dropped position in their original relative order
- **AND** unselected tasks SHALL remain in their relative positions

## REMOVED Requirements

### Requirement: Tasks are reorderable via drag in custom lists — Smart segments restriction

**Reason**: Smart segments (Today, Tomorrow, Upcoming) now support drag-and-drop reordering per the `timeline-reorder` spec. The restriction that "Smart segments SHALL NOT support drag-and-drop reordering" no longer applies.

**Migration**: The `Smart segments show no reorder affordance` scenario is removed. Timeline views now use the same `sortOrder` mechanism as custom lists. Existing task `sortOrder` values remain valid — tasks keep their existing positions, and timeline views begin sorting by `sortOrder` as the primary key.
