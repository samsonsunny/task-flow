## 1. ViewModel — group reorder method

- [x] 1.1 Add `moveGroups(fromOffsets:toOffset:)` method to `ListsTabViewModel` using the same midpoint algorithm as `moveLists`

## 2. View — wire .onMove

- [x] 2.1 Add `.onMove` to the groups `DisclosureGroup` `ForEach` in `ListView.swift`
- [x] 2.2 Wire the handler to `viewModel?.moveGroups(fromOffsets:toOffset:)`

## 3. Verify

- [x] 3.1 Build and verify no compile errors
- [ ] 3.2 Manual check: Groups can be dragged to reorder
- [ ] 3.3 Manual check: Group order persists after app restart
- [ ] 3.4 Manual check: Inbox stays pinned above groups
