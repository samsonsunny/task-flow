## 1. ListsTabView: Remove FAB and add inline rows

- [x] 1.1 Remove the `ReminderFloatingAddButton` overlay block from `ListsTabView` (lines 38-45 in ListView.swift)
- [x] 1.2 Make the Lists section header always visible (remove `if !items.isEmpty` guard on the section)
- [x] 1.3 Add `+` button to Lists section header that triggers list creation
- [x] 1.4 Add "+ New List" inline row at the bottom of the Lists section (styled as dashed circle + text, matching "Add Reminder" pattern)
- [x] 1.5 Add `+` button to Groups section header that triggers group creation
- [x] 1.6 Add "+ New Group" inline row at the bottom of the Groups section

## 2. List creation sheet

- [x] 2.1 Create `ListCreationSheet` view with navigation bar (Cancel/Create toolbar items)
- [x] 2.2 Add name text field (auto-focused) with Create button disabled when empty
- [x] 2.3 Add optional group association using a Menu picker showing existing groups
- [x] 2.4 Add "New Group…" option at the bottom of the group picker menu
- [x] 2.5 Wire sheet presentation from inline row and header `+` button taps

## 3. Group creation sheet

- [x] 3.1 Create `GroupCreationSheet` view with navigation bar (Cancel/Create toolbar items)
- [x] 3.2 Add name text field (auto-focused) with Create button disabled when empty
- [x] 3.3 Add optional list association using a Menu picker showing ungrouped lists (hidden when no lists exist)
- [x] 3.4 Add "New List…" option at the bottom of the list picker menu
- [x] 3.5 Wire sheet presentation from inline row and header `+` button taps

## 4. Mini-sheet for on-the-fly creation

- [x] 4.1 Create a reusable mini-sheet (single text field + Done) for creating a group during list creation
- [x] 4.2 Create a reusable mini-sheet (single text field + Done) for creating a list during group creation
- [x] 4.3 Wire mini-sheet dismissal to auto-update the parent sheet's association picker

## 5. ViewModel integration

- [x] 5.1 Wire list creation sheet confirm action to `viewModel?.createList(name:, group:)`
- [x] 5.2 Wire group creation sheet confirm action to `viewModel?.createGroup(name:, sourceList:)`
- [x] 5.3 Wire mini-sheet confirm actions to the same ViewModel methods

## 6. ViewModel unit tests (TaskFlowTests/ListsTabViewModelTests.swift)

- [x] 6.1 Add `@Test func createListWithoutGroup()` — call `vm.createList(name:)`, assert list exists with `group == nil`
- [x] 6.2 Add `@Test func createListWithGroup()` — create a group, then call `vm.createList(name:, group:)`, assert list is assigned to the group
- [x] 6.3 Add `@Test func createGroupWithoutList()` — call `vm.createGroup(name:, sourceList: nil)`, assert empty group exists
- [x] 6.4 Add `@Test func createGroupWithList()` — create an ungrouped list, then call `vm.createGroup(name:, sourceList:)`, assert group exists and list is assigned
- [x] 6.5 Add `@Test func createListRespectsSortOrder()` — assert new list gets a non-nil unique `sortOrder`
- [x] 6.6 Add `@Test func createGroupRespectsSortOrder()` — assert new group gets a non-nil unique `sortOrder`

## 7. UI tests (TaskFlowUITests)

- [x] 7.1 Add test for inline rows visible — assert "New List" and "New Group" static texts exist in Later tab
- [x] 7.2 Add test for header plus buttons — assert `+` buttons exist in Lists and Groups section headers
- [x] 7.3 Add test for list creation via sheet — tap inline row, enter name, tap Create, assert list appears
- [x] 7.4 Add test for group creation via sheet — tap inline row, enter name, tap Create, assert group appears
- [x] 7.5 Add test for list creation with group assignment — create list, pick group, assert list in group
- [x] 7.6 Add test for cancel dismisses sheet — assert no list/group created on Cancel
- [x] 7.7 Add test for Create disabled when name empty — assert Create button is disabled initially
- [x] 7.8 Add test for FAB removed — assert "reminder-create-button" does not exist in Later tab
- [x] 7.9 Verify existing lists, groups, and tasks are unaffected after all creation flows
