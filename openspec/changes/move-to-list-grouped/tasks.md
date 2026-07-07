## 1. Define shared type

- [x] 1.1 Add `ListSection` value type (Identifiable, title: String?, lists: [ReminderList]) to a shared location
- [x] 1.2 Skipped — `Draft.swift`'s `availableLists` serves list name resolution (different concern — no change needed)
- [x] 1.3 Skipped — same reason as 1.2

## 2. ViewModel: grouping logic

- [x] 2.1 Replace `TimelineViewModel.otherLists` with `listSections` computed property that groups lists: default list → grouped by `ReminderListGroup` → ungrouped
- [x] 2.2 Replace `ListDetailViewModel.otherLists` with `listSections` that also excludes current list
- [x] 2.3 Verify both ViewModels filter out the task's current list from all sections

## 3. View: sectioned rendering

- [x] 3.1 Change `TaskRowView.availableLists` to `listSections: [ListSection]`
- [x] 3.2 Update `TaskRowView` context menu to render `ForEach(listSections)` with `Section` wrapping each group
- [x] 3.3 When section title is nil, pass empty string to `Section` header (separator-only)
- [x] 3.4 Update `TaskNodeView` to accept and pass through `[ListSection]`

## 4. Wire up callers

- [x] 4.1 Update `TimelineView.swift` to pass `viewModel?.listSections ?? []` instead of `viewModel?.otherLists ?? []`
- [x] 4.2 Update `DetailView.swift` to pass `viewModel?.listSections ?? []` instead of `viewModel?.otherLists ?? []`
- [x] 4.3 Remove `otherLists` property from both ViewModels

## 5. Unit tests

- [x] 5.1 Test that `listSections` returns correct section order (default → grouped → ungrouped)
- [x] 5.2 Test that current list is excluded from all sections
- [x] 5.3 Test that with no groups, all lists appear in a single section
- [x] 5.4 Test that lists are correctly assigned to their group sections
- [x] 5.5 Test that ungrouped lists appear in the final section
- [x] 5.6 Verified — `DraftTests` compile fine (no change needed)

## 6. Verify

- [x] 6.1 Build and run the app — builds successfully
- [ ] 6.2 Manual test: context menu with no groups (verify flat list unchanged)
- [ ] 6.3 Manual test: context menu with groups (verify sections render correctly)
- [ ] 6.4 Manual test: verify Inbox is pinned at top
- [ ] 6.5 Run test suite (`cmd+U` or specified test command)
