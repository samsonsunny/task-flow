## 1. Enable Nesting in ViewModel

- [x] 1.1 Flip `nestSubtasks: false` → `nestSubtasks: true` in `DetailViewModel.recompute()` (line 80)
- [x] 1.2 Verify `TaskTreeFlattener.flatten()` now returns nodes with `depth > 0` for subtasks

## 2. Wire AppState into DetailView

- [x] 2.1 Add `@Environment(AppState.self) private var appState` to `ListDetailView`
- [x] 2.2 Pass `collapsedTasks: appState.collapsedTasks` to `viewModel?.update(...)` in `.onAppear` (line 146) and `.onChange(of: allTasks)` (line 150)

## 3. Add Depth Indentation

- [x] 3.1 Add `.padding(.leading, CGFloat(node.depth) * 20)` to `taskListRow()` in `DetailView.swift`

## 4. Add Chevron to TaskRowView

- [x] 4.1 Add `isExpanded: Bool = false` and `onToggleExpand: (() -> Void)? = nil` parameters to `TaskRowView`
- [x] 4.2 Render trailing chevron (`chevron.right` / `chevron.down`) when `subtaskSummary.total > 0`
- [x] 4.3 Apply 44×44pt expanded hit target for chevron button
- [x] 4.4 Suppress chevron tap when `isSelecting` (pass `nil` for `onToggleExpand`)

## 5. Wire Chevron to Collapse State

- [x] 5.1 In `DetailView.taskListRow()`, pass `isExpanded: !(appState.collapsedTasks.contains(task.persistentModelID))`
- [x] 5.2 Pass `onToggleExpand: { withAnimation { appState.toggleTaskCollapsed(task.persistentModelID) } }`
- [x] 5.3 Verify animated subtask rows appear/disappear on toggle

## 6. Update Tests

- [x] 6.1 Update `collapseHasNoEffectOnListDetailFlatNodes` in `ListDetailViewModelRegressionTests.swift` to assert nested behavior: 2 nodes when expanded, 1 node when collapsed
- [x] 6.2 Run full test suite to verify no regressions

## 7. Verify Existing Interactions

- [ ] 7.1 Verify drag-drop reparenting still works with nested nodes
- [ ] 7.2 Verify `onMove` reorder still works with nested nodes
- [ ] 7.3 Verify swipe actions (delete, postpone) work on both parent and subtask rows
- [ ] 7.4 Verify context menu works on both parent and subtask rows
- [ ] 7.5 Verify bulk selection works with nested nodes
- [ ] 7.6 Verify collapse state persists across app launches (UserDefaults)
