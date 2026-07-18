## 1. ViewModel — moveToTop / moveToBottom

- [x] 1.1 Add `moveToTop(task:)` to `DetailViewModel` using midpoint(between: nil, and: first sibling's sortOrder)
- [x] 1.2 Add `moveToBottom(task:)` to `DetailViewModel` using midpoint(between: last sibling's sortOrder, and: nil)
- [x] 1.3 Helper to get task's siblings (roots for root tasks, parent's children for child tasks)

## 2. TaskRowView — new closures

- [x] 2.1 Add `onMoveToTop: (() -> Void)?` and `onMoveToBottom: (() -> Void)?` optional closures to `TaskRowView`
- [x] 2.2 Add "Top" and "Bottom" buttons in context menu with Divider() separators
- [x] 2.3 Conditionally show only when closures are non-nil

## 3. DetailView — wire closures

- [x] 3.1 In `taskListRow()`, compute siblings and only provide closures when siblings.count > 1
- [x] 3.2 Wire `onMoveToTop` to `viewModel?.moveToTop(task:)`
- [x] 3.3 Wire `onMoveToBottom` to `viewModel?.moveToBottom(task:)`

## 4. Verify

- [x] 4.1 Build and verify no compile errors
- [ ] 4.2 Manual check: "Top" moves root to top of list
- [ ] 4.3 Manual check: "Bottom" moves root to bottom of list
- [ ] 4.4 Manual check: "Top" moves child to top of siblings
- [ ] 4.5 Manual check: "Bottom" moves child to bottom of siblings
- [ ] 4.6 Manual check: Actions hidden when only 1 task in context
- [ ] 4.7 Manual check: Actions hidden in Today/Tomorrow views
- [ ] 4.8 Manual check: Order persists after app restart
