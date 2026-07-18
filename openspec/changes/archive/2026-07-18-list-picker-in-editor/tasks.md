## 1. ListPickerView

- [x] 1.1 Create `ListPickerView.swift` in `Features/Editor/` with NavigationStack, search bar, and list
- [x] 1.2 Implement grouped list display using `buildListSections()` with checkmark on selected list
- [x] 1.3 Wire selection to dismiss picker and return selected list name via `@Environment(\\.dismiss)` + callback
- [x] 1.4 Add empty state for search with no results

## 2. Editor Integration

- [x] 2.1 Add "List" section row to `EditorView` showing current `draft.listName` with chevron
- [x] 2.2 Add `@State` for presenting `ListPickerView` and wire tap to presentation
- [x] 2.3 Pass callback from picker back to editor to update `draft.listName`

## 3. Pre-selection

- [x] 3.1 Verify `initialListID` is passed through from all entry points (list detail, timeline, quick capture)
- [x] 3.2 Ensure `EditorViewModel` uses `initialListID` to set `draft.listName` when creating new tasks

## 4. Polish

- [x] 4.1 Handle edge case: list renamed after draft created (fall back to Inbox)
- [x] 4.2 Verify save flow — `ReminderDraftMapper.apply()` resolves list correctly from updated draft
