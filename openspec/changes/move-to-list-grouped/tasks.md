## 1. Define shared type

- [ ] 1.1 Add `ListSection` value type (Identifiable, title: String?, lists: [ReminderList]) to a shared location
- [ ] 1.2 Update `Draft.swift` to use `[ListSection]` instead of `[ReminderList]` for `availableLists`
- [ ] 1.3 Fix `DraftTests.swift` to compile with new type

## 2. ViewModel: grouping logic

- [ ] 2.1 Replace `TimelineViewModel.otherLists` with `listSections` computed property that groups lists: default list → grouped by `ReminderListGroup` → ungrouped
- [ ] 2.2 Replace `ListDetailViewModel.otherLists` with `listSections` that also excludes current list
- [ ] 2.3 Verify both ViewModels filter out the task's current list from all sections

## 3. View: sectioned rendering

- [ ] 3.1 Change `TaskRowView.availableLists` to `listSections: [ListSection]`
- [ ] 3.2 Update `TaskRowView` context menu to render `ForEach(listSections)` with `Section` wrapping each group
- [ ] 3.3 When section title is nil, pass empty string to `Section` header (separator-only)
- [ ] 3.4 Update `TaskNodeView` to accept and pass through `[ListSection]`

## 4. Wire up callers

- [ ] 4.1 Update `TimelineView.swift` to pass `viewModel?.listSections ?? []` instead of `viewModel?.otherLists ?? []`
- [ ] 4.2 Update `DetailView.swift` to pass `viewModel?.listSections ?? []` instead of `viewModel?.otherLists ?? []`
- [ ] 4.3 Remove `otherLists` property from both ViewModels

## 5. Unit tests

- [ ] 5.1 Test that `listSections` returns correct section order (default → grouped → ungrouped)
- [ ] 5.2 Test that current list is excluded from all sections
- [ ] 5.3 Test that with no groups, all lists appear in a single section
- [ ] 5.4 Test that lists are correctly assigned to their group sections
- [ ] 5.5 Test that ungrouped lists appear in the final section
- [ ] 5.6 Verify existing `DraftTests` pass with the new type

## 6. Verify

- [ ] 6.1 Build and run the app
- [ ] 6.2 Manual test: context menu with no groups (verify flat list unchanged)
- [ ] 6.3 Manual test: context menu with groups (verify sections render correctly)
- [ ] 6.4 Manual test: verify Inbox is pinned at top
- [ ] 6.5 Run test suite (`cmd+U` or specified test command)
