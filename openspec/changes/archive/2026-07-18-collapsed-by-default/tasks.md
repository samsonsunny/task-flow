## 1. ReminderSegmentDetailView — move UI state to View

- [x] 1.1 Remove `showOverdue` and `collapsedTasks` from `ReminderSegmentViewModel`
- [x] 1.2 Add `@State private var showOverdue = false` and `@State private var collapsedTasks: Set<PersistentIdentifier> = []` to `ReminderSegmentDetailView`
- [x] 1.3 Initialize `collapsedTasks` in the View with all parent task IDs from `@Query` tasks on first render (use a `defaultCollapsed` flag)
- [x] 1.4 Update `rebuildTree()` to accept `collapsedTasks` as a parameter instead of reading from `self`
- [x] 1.5 Update `toggleCollapse()` in ViewModel to be a pure function or move toggle logic to View
- [x] 1.6 Wire `showOverdue` toggle in the View (replace `viewModel?.toggleShowOverdue()` with direct state toggle)

## 2. ListDetailView — same treatment

- [x] 2.1 Remove `collapsedTasks` from `ListDetailViewModel`
- [x] 2.2 Add `@State private var collapsedTasks: Set<PersistentIdentifier> = []` to `ListDetailView`
- [x] 2.3 Initialize `collapsedTasks` in the View with parent task IDs on first render
- [x] 2.4 Update `recompute()` to accept `collapsedTasks` as a parameter
- [x] 2.5 Move `toggleCollapse()` logic to the View

## 3. Verify

- [x] 3.1 Build and verify no compile errors
- [ ] 3.2 Manual check: Today/Tomorrow views show tasks collapsed by default
- [ ] 3.3 Manual check: Overdue section is collapsed by default
- [ ] 3.4 Manual check: List detail view shows tasks collapsed by default
- [ ] 3.5 Manual check: Expand/collapse choices survive tab switches
- [ ] 3.6 Manual check: App restart resets to collapsed defaults
