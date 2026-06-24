## Why

Users currently have no way to organize their task lists. Lists can be created but never renamed, deleted, or reordered — they're stuck in alphabetical order with "Reminders" pinned first. As the app scales to more lists, this becomes a constraint. These three operations (rename, delete, custom reorder) cover the full lifecycle of list management.

## What Changes

- **Rename a list**: Context menu on any list row in `ListsTabView` offers "Rename" → inline alert to edit the name. "Reminders" list omits the rename option (protected).
- **Delete a list**: Context menu offers "Delete List" → confirmation alert with two actions: "Move tasks to Reminders" (re-parents tasks to the default list) or "Delete All Tasks" (cascade delete). "Reminders" list omits the delete option (protected).
- **Custom list ordering**: `ListsTabView` gains drag-and-drop reorder via `.onMove`. The `ReminderList` model gets a `sortOrder: String?` field using the existing midpoint algorithm. "Reminders" is no longer pinned — all lists are freely reorderable.

## Capabilities

### New Capabilities
- `list-rename`: Rename any unprotected list via context menu. The default "Reminders" list is protected and cannot be renamed.
- `list-delete`: Delete a list via context menu with a confirmation step offering task re-parenting or cascade delete. The default "Reminders" list is protected and cannot be deleted.
- `list-reorder`: Drag-and-drop reorder of lists in `ListsTabView`. Reorder persists via a new `sortOrder` field using fractional string midpoint encoding.

### Modified Capabilities
*(None — no existing specs change their requirements)*

## Impact

- **Model**: `ReminderList` gains a `sortOrder: String?` field. Lightweight migration within the existing `TaskFlowSchemaV3` (no schema version bump needed — safe additive field).
- **Query**: `ListsTabView` changes from custom sort (pinned "Reminders" + alphabetical) to `@Query(sort: \.sortOrder, .forward)` with nil fallback.
- **UI**: `ListsTabView` gains `.onMove` for drag reorder, context menus on list rows for rename/delete, and confirmation alerts for delete with two cascade options.
- **Protected list**: The "Reminders" default list is hard-coded as protected — context menu omits rename and delete options.
