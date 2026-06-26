## 1. Create ListsTabViewModel

- [ ] 1.1 Create `TaskFlow/Features/Reminders/ViewModels/ListsTabViewModel.swift` with `@Observable` class
- [ ] 1.2 Add `modelContext`, `lists`, `groups`, `allTasks` properties and `update(lists:groups:allTasks:)` entry point
- [ ] 1.3 Add derived properties: `defaultList`, `ungroupedLists`
- [ ] 1.4 Add all dialog presentation state: `isCreatingList`, `newListName`, `isRenamePresented`, `renameList`, `renameText`, `deleteList`, `isCreatingGroup`, `newGroupName`, `groupSourceList`, `renameGroup`, `isGroupRenamePresented`, `groupRenameText`, `deleteGroup`

## 2. Move List CRUD to ViewModel

- [ ] 2.1 Add `createList(name:)` inserting list with sort order
- [ ] 2.2 Add `renameList(_:to:)` updating list name
- [ ] 2.3 Add `deleteList(_:moveTasksToDefault:)` with cascade logic
- [ ] 2.4 Add `listsInGroup(_:)` helper

## 3. Move Group CRUD to ViewModel

- [ ] 3.1 Add `createGroup(name:sourceList:)` inserting group with optional list assignment
- [ ] 3.2 Add `renameGroup(_:to:)` updating group name
- [ ] 3.3 Add `deleteGroup(_:)` with cascade: delete all tasks/lists in group, then delete group

## 4. Move Reorder and Group State to ViewModel

- [ ] 4.1 Add `moveLists(fromOffsets:toOffset:in:group:)` with midpoint/widen
- [ ] 4.2 Add `expandedGroupIDs` with `isGroupExpanded(_:)` and `toggleGroupExpanded(_:)` with UserDefaults persistence

## 5. Refactor ListsTabView to use ViewModel

- [ ] 5.1 Create VM from environment `modelContext` and `@Query` results
- [ ] 5.2 Replace all `@State` dialog properties with VM properties
- [ ] 5.3 Replace alert button actions with VM method calls
- [ ] 5.4 Replace `handleDelete`, `handleDeleteGroup`, `moveLists` with VM calls
- [ ] 5.5 Replace group DisclosureGroup binding with VM `isGroupExpanded`/`toggleGroupExpanded`
- [ ] 5.6 Remove all `@Environment(\.modelContext)` usage and direct mutations

## 6. Verify

- [ ] 6.1 Build succeeds with no warnings
- [ ] 6.2 Create list via FAB works
- [ ] 6.3 Rename list via context menu works
- [ ] 6.4 Delete list with "Move to Reminders" works
- [ ] 6.5 Delete list with "Delete All Tasks" works
- [ ] 6.6 Create group with optional source list works
- [ ] 6.7 Rename group works
- [ ] 6.8 Delete group with cascade works
- [ ] 6.9 Drag reorder within ungrouped section works
- [ ] 6.10 Drag reorder within group works
- [ ] 6.11 Move list to group via context menu works
- [ ] 6.12 Group expand/collapse persists across restarts
