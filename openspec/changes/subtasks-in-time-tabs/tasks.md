## 1. Shared TaskTreeFlattener utility

- [x] 1.1 Create `TaskTreeFlattener.swift` in `TaskFlow/Utilities/` with `TaskTreeNode` struct (same fields as `FlatTaskNode`) and `TaskTreeFlattener` struct with `static func flatten(roots: [TaskItem], collapsed: Set<PersistentIdentifier>, includeCompleted: Bool) -> [FlatTaskNode]`
- [x] 1.2 Move `FlatTaskNode` from `DetailViewModel.swift` into the new utility file so both VMs import from one place

## 2. Refactor ListDetailViewModel to use shared flattener

- [x] 2.1 Replace private `flattenTasks()` / `flattenNode()` methods in `ListDetailViewModel` with calls to `TaskTreeFlattener.flatten()`
- [x] 2.2 Verify behavior is identical: before/after `flatNodes` output matches for all existing scenarios

## 3. ReminderSegmentViewModel hierarchy integration

- [x] 3.1 Add `flatNodes: [FlatTaskNode]` and `collapsedTasks: Set<PersistentIdentifier>` properties to `ReminderSegmentViewModel`
- [x] 3.2 Add `toggleCollapse(_:)` method matching the pattern in `ListDetailViewModel`
- [x] 3.3 In `update()`, after computing `filteredTasks`, build the flattened node array: compute matched roots, build descendant dedup set, call `TaskTreeFlattener.flatten()` for roots, append standalone orphans at depth 0
- [x] 3.4 Replace `sortedFlatTasks` usage with `sorted(flatNodes)` where `flatNodes` drives the display

## 4. View wiring in ReminderSegmentDetailView

- [x] 4.1 Update `taskListRow()` to accept a `FlatTaskNode` (or pass `nestingDepth`, `subtaskCount`, `isCollapsed`, `onToggleCollapse` from the node)
- [x] 4.2 Update `todayLikeContent()`, `flatContent()`, and `groupedContent()` to iterate over `vm.flatNodes` instead of `vm.sortedFlatTasks`
- [x] 4.3 Add `.animation()` on collapse state changes in the time tab views

## 5. Upcoming section grouping with flattening

- [x] 5.1 Add `flatNodes(for sectionTasks:)` helper to `ReminderSegmentViewModel` that converts section-scoped tasks to flat nodes with hierarchy
- [x] 5.2 Update `upcomingContent()` and `monthSectionView()` to use flat nodes inside each section, passing hierarchy params to `TaskRowView`

## 6. Remove old flat-row suppression behavior

- [x] 6.1 Verify no code path suppresses `nestingDepth`, `subtaskCount`, `isCollapsed`, or `onToggleCollapse` in segment views
- [x] 6.2 Remove the "Segment views suppress nesting indicators" scenario from code comments/docs if referenced

## 7. Update mental model spec

- [x] 7.1 Update `openspec/specs/app-mental-model/spec.md` to reflect the final subtask-in-time-tabs behavior, replacing the "under exploration" note with the final rules

## 8. Write tests

- [x] 8.1 Write `TaskTreeFlattenerTests` — pure function tests covering basic shape, collapse, completed children, empty roots, deep nesting, sort ordering (see `specs/test-plan/spec.md`)
- [x] 8.2 Write `ReminderSegmentViewModelTests` — pipeline tests covering Rule 1 (parent-driven), Rule 2 (orphan standalone), dedup, collapse/expand, per-view independence, upcoming section grouping (see `specs/test-plan/spec.md`)
- [x] 8.3 ReminderSegmentDetailView wiring — covered by UI tests (flex tests will validate hierarchy params)
- [x] 8.4 Write `ListDetailViewModelRegressionTests` — before/after comparison of `flatNodes` output to verify shared flattener extraction doesn't change behavior (see `specs/test-plan/spec.md`)

## 9. Add UI test fixture and tests

- [x] 9.1 Add `UITEST_FIXTURE_SUBTASKS_INLINE` fixture to `TaskPreviewData` — creates parent "Parent Project" with three children (today, tomorrow, no date) plus an orphan subtask with `dueDate=today` whose parent has no date (see `specs/test-plan/spec.md`)
- [x] 9.2 Register new fixture in `TaskFlowApp.swift` so the launch argument loads the fixture
- [x] 9.3 Add `subtask-chevron` accessibility identifier to the chevron button in `TaskRowView` so UI tests can locate it
- [x] 9.4 Write UI test `testParentWithChildrenShowsInlineInToday` — verifies all children visible under parent
- [x] 9.5 Write UI test `testCollapseTapHidesChildren` / `testExpandShowsChildrenAfterCollapse` — tap chevron, verify children gone, tap again, verify children back
- [x] 9.6 Write UI test `testOrphanSubtaskAppearsStandalone` — orphan visible without parent context, no chevron (verified via `testChevronOnParentOnly`)
- [x] 9.7 Write UI test `testChildInTomorrowTabWhenParentDifferentDate` — child in Tomorrow, parent not visible
- [x] 9.8 Write UI test `testListDetailHierarchyRegression` — Later tab list still shows proper hierarchy (regression check)
