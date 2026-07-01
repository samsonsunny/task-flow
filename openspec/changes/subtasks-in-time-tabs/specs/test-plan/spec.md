## ADDED Requirements

### Requirement: TaskTreeFlattener is tested as a pure function
`TaskTreeFlattener.flatten()` SHALL be tested as a pure function — no SwiftData context needed. Tests SHALL construct `TaskItem` instances directly and assert on `[FlatTaskNode]` output.

#### Scenario: Single root with no children
- **WHEN** `flatten(roots: [root], collapsed: [], includeCompleted: false)` is called
- **THEN** result SHALL be `[FlatTaskNode(id: root.id, depth: 0, subtaskCount: 0)]`

#### Scenario: Root with one child
- **WHEN** roots contains a task with one direct child
- **THEN** result SHALL be `[root d0, child d1]`

#### Scenario: Root with two children respects sortOrder
- **WHEN** root has two children with sortOrder "aaa" and "bbb"
- **THEN** child "aaa" SHALL appear before child "bbb"

#### Scenario: Three levels of nesting produce correct depths
- **WHEN** grandparent → parent → child
- **THEN** result SHALL be `[gp d0, parent d1, child d2]`

#### Scenario: Empty roots returns empty array
- **WHEN** roots is empty
- **THEN** result SHALL be `[]`

#### Scenario: Collapsed root omits children
- **WHEN** root is in the collapsed set
- **THEN** result SHALL be `[root d0]` with no children

#### Scenario: Child collapsed under expanded root includes child but omits grandchildren
- **WHEN** root expanded, child in collapsed set
- **THEN** result SHALL be `[root d0, child d1]` (child's children pruned)

#### Scenario: includeCompleted=false excludes completed children
- **WHEN** a child has `isCompleted = true`
- **AND** `includeCompleted = false`
- **THEN** the completed child SHALL NOT appear in the output
- **AND** the parent's `subtaskCount` SHALL exclude it

#### Scenario: includeCompleted=true includes completed children
- **WHEN** a child has `isCompleted = true`
- **AND** `includeCompleted = true`
- **THEN** the completed child SHALL appear in the output

#### Scenario: Leaf task has subtaskCount of 0
- **WHEN** a task has no children
- **THEN** `subtaskCount` SHALL be 0

#### Scenario: Task with 2 children has subtaskCount of 2
- **WHEN** a task has 2 direct children
- **THEN** `subtaskCount` SHALL be 2

#### Scenario: Very deep nesting does not crash
- **WHEN** a hierarchy of 10+ levels is flattened
- **THEN** the function returns without throwing

#### Scenario: Tasks without sortOrder have stable ordering
- **WHEN** children have nil or empty sortOrder
- **THEN** they SHALL appear in a deterministic order (e.g., insertion order or by persistentModelID)

### Requirement: ReminderSegmentViewModel flattening pipeline is tested
The `ReminderSegmentViewModel.update()` method SHALL produce correct `flatNodes` given known inputs. These tests SHALL use a mocked model context or in-memory SwiftData store.

#### Scenario: Parent due today, child due today → inline
- **WHEN** a root task has `dueDate = today`
- **AND** its child also has `dueDate = today`
- **AND** `segment = .today`
- **THEN** `flatNodes` SHALL be `[parent d0, child d1]`
- **AND** the child SHALL NOT appear as standalone depth 0

#### Scenario: Parent due today, child due tomorrow → child inline in today, standalone in tomorrow
- **WHEN** a root task has `dueDate = today`
- **AND** its child has `dueDate = tomorrow`
- **AND** `segment = .today`
- **THEN** `flatNodes` SHALL be `[parent d0, child d1]`
- **WHEN** `segment = .tomorrow`
- **THEN** `flatNodes` SHALL be `[child d0]` (standalone orphan)

#### Scenario: Parent due today, child no date → child visible in today
- **WHEN** a root task has `dueDate = today`
- **AND** its child has no `dueDate`
- **AND** `segment = .today`
- **THEN** `flatNodes` SHALL be `[parent d0, child d1]`

#### Scenario: Child due today, parent no date → orphan standalone
- **WHEN** a child has `dueDate = today`
- **AND** its parent has no `dueDate`
- **AND** `segment = .today`
- **THEN** `flatNodes` SHALL be `[child d0]`

#### Scenario: Child due today, parent due tomorrow → orphan in today, inline in tomorrow
- **WHEN** a child has `dueDate = today`
- **AND** its parent has `dueDate = tomorrow`
- **THEN** `segment = .today` → `flatNodes` SHALL be `[child d0]`
- **AND** `segment = .tomorrow` → `flatNodes` SHALL be `[parent d0, child d1]`

#### Scenario: Dedup — child not duplicated when under parent
- **WHEN** parent and child both have `dueDate = today`
- **AND** `segment = .today`
- **THEN** `flatNodes.count` SHALL be 2 (parent + child, not 3)

#### Scenario: Collapse hides children in timeline view
- **WHEN** parent with children is in `collapsedTasks`
- **AND** `segment = .today`
- **THEN** `flatNodes` SHALL contain only the parent node

#### Scenario: Expand shows children
- **WHEN** parent is removed from `collapsedTasks`
- **AND** `toggleCollapse()` is called
- **THEN** `flatNodes` SHALL include the children again

#### Scenario: Collapse state is per-ViewModel instance
- **WHEN** Today VM has parent collapsed
- **AND** Tomorrow VM has the same parent
- **THEN** the parent SHALL be expanded in Tomorrow VM

#### Scenario: Tree in upcoming section stays in parent's section
- **WHEN** a root has `dueDate = D+3`
- **AND** its child has `dueDate = D+7`
- **AND** `segment = .upcoming`
- **THEN** both parent and child SHALL appear in the D+3 day section
- **AND** the child SHALL NOT appear in the D+7 section

#### Scenario: Two roots same day produce two trees
- **WHEN** two unrelated root tasks both have `dueDate = D+3`
- **AND** each has one child
- **THEN** the D+3 section SHALL contain 4 flat nodes (2 trees)

#### Scenario: Completed parent in timeline cascades to children
- **WHEN** a parent in a time tab is marked completed
- **THEN** `completeDescendants()` SHALL be called
- **AND** all children SHALL be marked completed

### Requirement: TaskRowView hierarchy params are wired in segment views
The `taskListRow()` function in `ReminderSegmentDetailView` SHALL pass the correct hierarchy parameters to `TaskRowView` for each flat node.

#### Scenario: Segment view passes nestingDepth to TaskRowView
- **WHEN** a flat node has depth=2 in a segment view
- **THEN** `taskListRow()` SHALL pass `nestingDepth: 2` to `TaskRowView`
- **AND** the row SHALL be indented by 40 points

#### Scenario: Segment view passes subtaskCount to TaskRowView
- **WHEN** a flat node has `subtaskCount=3`
- **THEN** `taskListRow()` SHALL pass `subtaskCount: 3` to `TaskRowView`
- **AND** "3 ›" SHALL appear in the metadata line

#### Scenario: Segment view passes isCollapsed to TaskRowView
- **WHEN** a parent is collapsed
- **THEN** `taskListRow()` SHALL pass `isCollapsed: true` to `TaskRowView`
- **AND** the chevron SHALL point right

#### Scenario: Segment view wires onToggleCollapse
- **WHEN** a parent has children
- **THEN** `taskListRow()` SHALL pass a non-nil `onToggleCollapse` closure
- **AND** tapping the chevron SHALL toggle the parent's collapse state

#### Scenario: Leaf task does not get onToggleCollapse
- **WHEN** a task has no children
- **THEN** `taskListRow()` SHALL pass `nil` for `onToggleCollapse`
- **AND** no chevron SHALL be displayed

### Requirement: ListDetailViewModel regression is verified
After extracting the flattener, `ListDetailViewModel.flatNodes` SHALL produce identical output for the same inputs.

#### Scenario: FlatNodes unchanged after refactor
- **WHEN** `ListDetailViewModel` has the same `tasks`, `collapsedTasks`, and model state
- **BEFORE** (inline flattener) and **AFTER** (shared flattener) the refactor
- **THEN** `flatNodes` SHALL be identical (same count, same order, same depths, same subtaskCounts)

### Requirement: UI test fixture seeds hierarchical tasks
A new launch argument `UITEST_FIXTURE_SUBTASKS_INLINE` SHALL create a known set of parent-child task relationships for UI testing.

#### Scenario: Fixture creates parent with mixed children
- **WHEN** app launches with `UITEST_FIXTURE_SUBTASKS_INLINE`
- **THEN** a root task "Parent Project" exists with `dueDate = today`, containing:
- **AND** child "Child with today date" with `dueDate = today`
- **AND** child "Child with tomorrow date" with `dueDate = tomorrow`
- **AND** child "Child no date" with no `dueDate`
- **AND** an orphan subtask "Orphan subtask" with `dueDate = today` whose parent has no `dueDate`

### Requirement: UI tests verify hierarchy visibility in time tabs
UI tests SHALL verify that parent-child relationships render correctly in the Today and Tomorrow tabs.

#### Scenario: Today tab shows parent with children indented
- **WHEN** app launches with `UITEST_FIXTURE_SUBTASKS_INLINE` and shows the Today tab
- **THEN** `staticText` "Parent Project" SHALL exist
- **AND** `staticText` "Child with today date" SHALL exist
- **AND** `staticText` "Child no date" SHALL exist  (visible despite no due date)
- **AND** "Child with tomorrow date" SHALL exist (visible inline despite different date)

#### Scenario: Parent shows chevron, leaf shows no chevron
- **WHEN** app launches with `UITEST_FIXTURE_SUBTASKS_INLINE` in Today tab
- **THEN** the row for "Parent Project" SHALL have a visible chevron button
- **AND** the row for "Child with today date" SHALL NOT have a chevron button

#### Scenario: Tap collapse chevron hides children
- **WHEN** app launches with `UITEST_FIXTURE_SUBTASKS_INLINE` in Today tab
- **AND** user taps the chevron button on "Parent Project"
- **THEN** "Child with today date" SHALL no longer be visible
- **AND** "Child no date" SHALL no longer be visible
- **AND** "Parent Project" SHALL still be visible

#### Scenario: Tap expand chevron shows children again
- **WHEN** parent is collapsed (children hidden)
- **AND** user taps the chevron button again
- **THEN** "Child with today date" SHALL be visible again
- **AND** "Child no date" SHALL be visible again

#### Scenario: Orphan subtask appears standalone without parent
- **WHEN** app launches with `UITEST_FIXTURE_SUBTASKS_INLINE` in Today tab
- **THEN** "Orphan subtask" SHALL exist as a row
- **AND** "Orphan subtask" SHALL NOT show a chevron (depth 0, leaf)
- **AND** no row containing the orphan's parent SHALL exist (parent has no due date)

#### Scenario: Tomorrow tab shows orphan child from different-date parent
- **WHEN** `UITEST_FIXTURE_SUBTASKS_INLINE` launches and user taps Tomorrow tab
- **THEN** "Child with tomorrow date" SHALL exist in Tomorrow tab
- **AND** "Parent Project" SHALL NOT exist in Tomorrow tab (parent due today, not tomorrow)
- **AND** "Child with tomorrow date" SHALL NOT show a chevron (orphan, depth 0)

#### Scenario: Subtask count appears in parent's metadata
- **WHEN** `UITEST_FIXTURE_SUBTASKS_INLINE` launches in Today tab
- **THEN** the row for "Parent Project" SHALL display metadata containing the number 3 (three direct children)

#### Scenario: No duplicate rows for same-date child
- **WHEN** `UITEST_FIXTURE_SUBTASKS_INLINE` launches in Today tab
- **THEN** exactly one row with text "Child with today date" SHALL exist (not duplicated as standalone)

#### Scenario: List detail still shows hierarchy correctly
- **WHEN** `UITEST_FIXTURE_SUBTASKS_INLINE` launches
- **AND** user navigates to Later tab
- **AND** taps the list containing the tasks
- **THEN** "Parent Project" SHALL show with children indented and chevron
- **AND** tapping chevron collapses children (regression check)
