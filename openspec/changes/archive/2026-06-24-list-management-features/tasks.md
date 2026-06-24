## 1. Data Model

- [x] 1.1 Add `sortOrder: String?` attribute to `ReminderList` in new `TaskFlowSchemaV4` with V3→V4 lightweight migration
- [x] 1.2 Add `assignInitialSortOrder(_:)` helper for ReminderList (mirrors TaskItem pattern, appends new list at end)

## 2. List Reorder in ListsTabView

- [x] 2.1 Change `@Query(sort: \ReminderList.createdAt)` to `@Query(sort: \ReminderList.sortOrder, order: .forward)` in `ListsTabView`
- [x] 2.2 Remove custom `sortedLists` computed property (pinned "Reminders" + alphabetical logic)
- [x] 2.3 Add `.onMove` modifier to `ForEach` in `ListsTabView`
- [x] 2.4 Implement `moveLists(fromOffsets:toOffset:)` handler reusing `midpoint(between:and:)` and `widen(_:)` from `SortOrderMidpoint.swift`
- [x] 2.5 Assign initial `sortOrder` when creating a new list in the "New List" alert

## 3. Backfill sortOrder for Existing Lists

- [x] 3.1 Write backfill that assigns sortOrders to existing `ReminderList` entries without a `sortOrder`, based on current display order (Reminders first, then alphabetical by name)
- [x] 3.2 Call backfill from `ContentView.onAppear` (alongside existing `backfillSortOrdersIfNeeded`)

## 4. Rename List via Context Menu

- [x] 4.1 Add `.contextMenu` modifier to list rows in `ListsTabView`
- [x] 4.2 Add "Rename" option to context menu — visible only when `list.name != ReminderDefaults.defaultListName`
- [x] 4.3 Present rename alert with text field pre-filled with current name on "Rename" tap
- [x] 4.4 Handle confirm: trim input, reject empty, update `list.name` on valid input
- [x] 4.5 Handle cancel: dismiss alert with no changes

## 5. Delete List via Context Menu

- [x] 5.1 Add "Delete List" option to context menu — visible only when `list.name != ReminderDefaults.defaultListName`
- [x] 5.2 Present delete confirmation alert with two buttons: "Move tasks to Reminders" (default) and "Delete All Tasks" (destructive)
- [x] 5.3 Implement "Move tasks to Reminders": re-parent each task to "Reminders" list, then delete the list
- [x] 5.4 Implement "Delete All Tasks": delete all tasks in the list (cancel notifications), then delete the list
- [x] 5.5 Handle cancel: dismiss alert with no changes

## 6. Verify

- [x] 6.1 "Reminders" list has no Rename or Delete options in context menu
- [x] 6.2 "Reminders" list is freely reorderable via drag
- [x] 6.3 Build succeeds, no regressions in `ListDetailView` or task creation
