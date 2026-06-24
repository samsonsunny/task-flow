## 1. Data Model & Migration

- [x] 1.1 Add `ReminderListGroup` model to `TaskFlowSchemaV7` with `name: String`, `sortOrder: String?`, `createdAt: Date`, and `lists: [ReminderList]` relationship
- [x] 1.2 Add optional inverse `group: ReminderListGroup?` to `ReminderList` in V7
- [x] 1.3 Create `TaskFlowSchemaV7` as a new `VersionedSchema` and add `.lightweight` migration stage V6→V7 in `TaskFlowMigrationPlan`
- [x] 1.4 Update the `typealias` statements at the bottom of `TaskItem.swift` to point to V7 types

## 2. Shared Sort Utilities

- [x] 2.1 Extract `midpoint(between:and:)` and `widen(_:)` from `ListDetailView` into a shared utility (e.g., `SortOrderMidpoint.swift` in `Utilities/`)
- [x] 2.2 Update `ListDetailView` to import and use the shared utility instead of local functions

## 3. ListsTabView Rewrite — Group Sections & Expand/Collapse

- [x] 3.1 Replace the flat `List` in `ListsTabView` with a sectioned layout: pinned default list row, group sections (expandable), ungrouped list section
- [x] 3.2 Implement group header view with name, expand/collapse chevron, and incomplete task count
- [x] 3.3 Implement expand/collapse toggle via UserDefaults using key `"list-group-expanded-\(group.persistentModelID)"`, defaulting to expanded (using `@State` Set for SwiftUI reactivity)
- [x] 3.4 Render member lists inside expanded group sections using `ForEach`
- [x] 3.5 Render ungrouped lists below all groups using `ForEach`
- [x] 3.6 Query groups sorted by `sortOrder` and lists within groups / ungrouped by their `sortOrder`

## 4. Context Menu — Group Creation & Move to Group

- [x] 4.1 Add `.contextMenu` to non-default list rows with "Create New Group" option that prompts for group name and moves the list into the new group
- [x] 4.2 Add "Move to Group" submenu listing all existing groups plus "None" (to ungroup) and "New Group..." (to create and move)
- [x] 4.3 Ensure the default "Reminders" list excludes the context menu group options

## 5. Drag-and-Drop Reorder

- [x] 5.1 Implement `.onDrag`/`.onDrop` on group section headers for group reorder (carries `persistentModelID`, updates `sortOrder`)
- [x] 5.2 Implement `.onMove` on list rows within group sections for intra-group reorder
- [x] 5.3 Implement `.onMove` on ungrouped list rows for ungrouped reorder
- [x] 5.4 Implement cross-group drop: `GroupDropDelegate` handles dragging a list from one group to another
- [x] 5.5 Implement drop from group to ungrouped section: `UngroupedDropDelegate` handles dragging a list out of a group
- [x] 5.6 Add drop zone delegates per section (GroupDropDelegate, UngroupedDropDelegate)

## 6. Polish & Edge Cases

- [x] 6.1 Handle empty groups — show header with count 0 and empty expanded area
- [x] 6.2 Ensure new lists created via "+" button are ungrouped and appended to ungrouped section
