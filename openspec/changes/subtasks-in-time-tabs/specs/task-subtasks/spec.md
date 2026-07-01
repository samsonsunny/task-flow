## MODIFIED Requirements

### Requirement: Segment views show subtasks flat
Reminder segment views (Today, Tomorrow, Upcoming) SHALL render subtasks inline under their parent with full hierarchy (indentation, collapse/expand chevrons, subtask count). The following rules govern display:

**Rule 1 — Parent-driven display**: When a root-level task passes a segment view's time filter (based on its own `dueDate`), ALL its descendants SHALL appear inline beneath it regardless of their individual `dueDate` values. Descendants without a `dueDate` inherit visibility from their ancestor's filter match.

**Rule 2 — Orphan subtasks**: When a subtask passes a segment view's time filter but its parent (and all higher ancestors) do NOT pass the filter, the subtask SHALL appear as a standalone row at depth 0 with no parent context pulled in.

#### Scenario: Parent in Today shows all descendants inline
- **WHEN** a root-level task has a `dueDate` of today
- **AND** the user is viewing the Today segment
- **THEN** the root task SHALL appear in the Today segment
- **AND** ALL descendant subtasks (regardless of their own due dates) SHALL appear inline beneath it
- **AND** each descendant SHALL be indented by `depth * 20` points
- **AND** each descendant SHALL display the standard `TaskRowView` with collapse/expand controls, subtask count, and completion state

#### Scenario: Undated subtask visible under parent in time tab
- **WHEN** a root-level task has a `dueDate` of today
- **AND** that task has a subtask with no `dueDate`
- **THEN** the undated subtask SHALL appear inline under its parent in the Today segment (and any other segment the parent matches)
- **AND** the subtask SHALL NOT appear as a standalone row

#### Scenario: Subtask matches filter but parent does not (orphan)
- **WHEN** a subtask has a `dueDate` of today
- **AND** its parent has no `dueDate` (or a `dueDate` that does not match today)
- **THEN** the subtask SHALL appear in the Today segment as a standalone row at depth 0
- **AND** no parent context (indentation, parent row, chevron) SHALL be displayed

#### Scenario: Dated child in a different time slot than parent
- **WHEN** a parent task has a `dueDate` of today
- **AND** a child subtask has a `dueDate` of tomorrow
- **THEN** the child SHALL appear inline under the parent in the Today segment (Rule 1)
- **AND** the child SHALL also appear as a standalone row in the Tomorrow segment (Rule 2, because the parent does not match Tomorrow's filter)

#### Scenario: Expand on parent shows hidden descendants
- **WHEN** a parent task in a segment view is in collapsed state
- **AND** user taps the collapse/expand chevron
- **THEN** all descendant subtasks SHALL appear inline with animation
- **AND** the chevron SHALL update to indicate expanded state

#### Scenario: Collapse on parent hides descendants
- **WHEN** a parent task in a segment view is in expanded state
- **AND** user taps the collapse/expand chevron
- **THEN** all descendant subtasks SHALL be hidden with animation
- **AND** the chevron SHALL update to indicate collapsed state

## ADDED Requirements

### Requirement: Deduplication within same view
When a subtree is rendered inline under a root that passes the time filter, any subtask that ALSO independently passes the filter SHALL NOT appear as an additional standalone row in the same view.

#### Scenario: Subtask not duplicated when under parent
- **WHEN** a parent task has a `dueDate` of today
- **AND** a child subtask also has a `dueDate` of today
- **THEN** the child SHALL appear once — inline under its parent
- **AND** the child SHALL NOT appear as a separate standalone row in the Today segment

### Requirement: Collapse state is per-view
Each segment view (Today, Tomorrow, Upcoming) SHALL maintain its own independent collapse state. Collapsing a parent in one view SHALL NOT affect its state in other views or in ListDetailView.

#### Scenario: Collapse state independent between views
- **WHEN** user collapses a parent in the Today segment
- **THEN** the parent SHALL remain expanded in the Tomorrow segment (if visible there)
- **AND** the parent SHALL remain expanded in ListDetailView

### Requirement: Completion cascade respects hierarchy in all views
When a parent task is completed in a segment view, all descendant subtasks SHALL also be completed. The `completeDescendants()` and `uncompleteDescendants()` methods SHALL work identically in all views.

#### Scenario: Complete parent from segment view cascades
- **WHEN** user completes a parent task in the Today segment
- **THEN** all descendant subtasks SHALL be marked completed
- **AND** their notifications SHALL be cancelled
- **AND** the inline hierarchy SHALL update to reflect completed state
