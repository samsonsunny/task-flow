## ADDED Requirements

### Requirement: TaskRowView Equatable conformance excludes closures from equality
When evaluating equality for `TaskRowView`, the system SHALL compare only value-type and identity fields. Closure properties (`onToggleCompletion`, `onTap`, `onDelete`, `onMoveToToday`, `onMoveToTomorrow`, `onMoveToLater`, `onSchedule`, `onMoveToList`, `onToggleCollapse`) and the `listSections` array SHALL NOT participate in equality comparison, as they change identity on every parent build and would defeat render-skipping.

#### Scenario: Row with changed closures but same visual state skips re-render
- **WHEN** a parent view rebuilds and creates new closure instances for `onToggleCompletion` and `onTap`
- **AND** the row's `persistentModelID`, `isCompletedVisualState`, `subtaskCount`, `isCollapsed`, and `nestingDepth` are unchanged
- **THEN** the row SHALL skip re-rendering

#### Scenario: Row with changed listSections but same visual state skips re-render
- **WHEN** a parent view rebuilds and passes a new `listSections` array instance
- **AND** the row's `persistentModelID`, `isCompletedVisualState`, `subtaskCount`, `isCollapsed`, and `nestingDepth` are unchanged
- **THEN** the row SHALL skip re-rendering
