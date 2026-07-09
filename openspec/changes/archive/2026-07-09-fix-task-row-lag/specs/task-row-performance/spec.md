## ADDED Requirements

### Requirement: TaskRowView uses cached NSDataDetector for link detection
The system SHALL compile the `NSDataDetector` instance used for link detection in `attributedTitle` exactly once as a `static let` on `TaskRowView`. The cached instance SHALL be reused across all row evaluations and all row instances. No new `NSDataDetector` instance SHALL be created during `body` evaluation or `attributedTitle` computation.

#### Scenario: Link detection uses shared cached detector
- **WHEN** `TaskRowView.body` is evaluated
- **THEN** the `attributedTitle` property SHALL use a pre-compiled shared `NSDataDetector` instance
- **AND** no `NSDataDetector` initializer SHALL be called during the evaluation

#### Scenario: Links still render correctly with cached detector
- **WHEN** a task title contains a valid URL (e.g., "Visit https://example.com")
- **THEN** the URL SHALL be detected and rendered as a tappable link in the attributed title

### Requirement: TaskRowView conforms to Equatable for render skipping
`TaskRowView` SHALL conform to `Equatable`. Equality SHALL be determined by the following fields: `task.persistentModelID`, `isCompletedVisualState`, `subtaskCount`, `isCollapsed`, `nestingDepth`. Closure parameters (`onToggleCompletion`, `onTap`, etc.) SHALL NOT participate in equality comparison.

#### Scenario: Identical row inputs skip re-render
- **WHEN** a `TaskRowView` is re-evaluated with the same `persistentModelID`, `isCompletedVisualState`, `subtaskCount`, `isCollapsed`, and `nestingDepth` as the previous evaluation
- **THEN** SwiftUI SHALL skip the re-render (the view body is not re-evaluated)

#### Scenario: Completion state change triggers re-render
- **WHEN** `isCompletedVisualState` changes from `false` to `true` for a row
- **THEN** the row SHALL re-render with completed styling

#### Scenario: Collapse state change triggers re-render
- **WHEN** `isCollapsed` changes for a parent task row
- **THEN** the row SHALL re-render with updated chevron orientation

### Requirement: listSections is a stored property in ViewModels
Both `ReminderSegmentViewModel` and `ListDetailViewModel` SHALL expose `listSections` as a stored property of type `[ListSection]`. The property SHALL be recomputed inside the `update()` / `recompute()` method and SHALL NOT be a computed property that allocates on every access.

#### Scenario: listSections remains stable between updates
- **WHEN** a ViewModel's `update()` is called with unchanged data
- **THEN** the `listSections` array identity SHALL remain the same (same array reference)

#### Scenario: listSections updates when lists change
- **WHEN** the available reminder lists change (e.g., a list is created or deleted)
- **THEN** `listSections` SHALL be recomputed to reflect the new list set

### Requirement: ListDetailView scopes task fetching to the current list
`ListDetailView` SHALL fetch only tasks belonging to the current list (identified by `listID`) rather than fetching all tasks in the database. The `@Query` or `FetchDescriptor` SHALL filter tasks by their `reminderList` association.

#### Scenario: Only list tasks are fetched
- **WHEN** `ListDetailView` appears for a list with 5 tasks
- **THEN** only those 5 tasks (plus the `allTasks` reference needed for move operations) SHALL be loaded into memory

#### Scenario: Task moved to another list disappears from view
- **WHEN** a task is moved from the current list to a different list
- **THEN** the task SHALL no longer appear in the current `ListDetailView`

### Requirement: onChange handlers guard against no-op updates
`ReminderSegmentDetailView`'s `onChange(of: tasks)` and `onChange(of: reminderLists)` handlers SHALL compare the incoming data against the ViewModel's stored data before calling `update()`. If the data is referentially identical (`===`), the `update()` call SHALL be skipped.

#### Scenario: Unrelated mutation does not trigger full recompute
- **WHEN** a task in a different list is modified
- **THEN** the `onChange(of: tasks)` handler SHALL detect referential identity and skip the `update()` call

#### Scenario: Same-list mutation triggers recompute
- **WHEN** a task in the current list is modified
- **THEN** the `onChange(of: tasks)` handler SHALL call `update()` to reflect the change
