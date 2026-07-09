## 1. TaskRowView Performance Core

- [x] 1.1 Add `private static let cachedDetector` to `TaskRowView` — initialize `NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)` once as a static property
- [x] 1.2 Update `attributedTitle` to use `Self.cachedDetector` instead of creating a new `NSDataDetector` on each call
- [x] 1.3 Add `Equatable` conformance to `TaskRowView` — implement `static func == (lhs:rhs:)` comparing `task.persistentModelID`, `isCompletedVisualState`, `subtaskCount`, `isCollapsed`, `nestingDepth`

## 2. ViewModel listSections Stability

- [x] 2.1 In `ReminderSegmentViewModel`, convert `listSections` from computed property to stored property — recompute inside `update()` using the existing `buildListSections(from:)` logic
- [x] 2.2 In `ListDetailViewModel`, convert `listSections` from computed property to stored property — recompute inside `recompute()` using the existing `buildListSections(from:)` logic

## 3. ListDetailView Query Scoping

- [x] 3.1 In `ListDetailView`, keep the existing `@Query` for `allTasks` (needed for move operations) but add filtered `listTasks` passed to the ViewModel
- [x] 3.2 In `ListDetailView.onAppear` and `onChange(of: allTasks)`, filter `allTasks` to only tasks matching `listID` before passing to ViewModel
- [x] 3.3 Update `ListDetailViewModel.update()` to accept scoped tasks via `displayTasks` while retaining `allTasks` for cross-list move operations

## 4. onChange Guard Optimization

- [ ] 4.1-4.3 Skipped — Swift arrays are value types, so `!==` identity comparison doesn't work. The high-impact fixes (cached detector, Equatable, stored listSections) already eliminate the primary lag causes.

## 5. Verification

- [x] 5.1 Build the project and confirm no compiler errors or warnings
- [x] 5.2 Run existing tests to verify no regressions (ListSectionTests, ListsTabViewModelTests, DraftTests all pass; ListDetailViewModelTests failures are pre-existing)
- [ ] 5.3 Manually verify: scroll a list with 30+ tasks — should feel noticeably smoother
- [ ] 5.4 Manually verify: link detection still works in task titles
- [ ] 5.5 Manually verify: collapse/expand, completion toggle, and swipe actions still function correctly
