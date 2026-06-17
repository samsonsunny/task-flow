## Why

Tasks in custom lists are currently sorted by creation date (newest first), giving users no control over task ordering. As lists grow, important tasks get buried and users can't prioritize visually. Drag-and-drop reordering lets users arrange tasks in any sequence they choose — the most natural interaction for task management.

## What Changes

- Add `sortOrder: String?` field to `TaskItem` (SwiftData V3 schema, lightweight migration)
- `ListDetailView` gains drag-and-drop reordering via `.onMove` modifier
- Use fractional string midpoint algorithm to assign sort orders — only the moved task gets updated per drag
- New tasks auto-assigned a sortOrder at the end of the list
- Existing tasks backfilled with initial sortOrder based on current createdAt order (per list)
- Rare adjacency edge case handled by local 3-item re-index (not full list)
- Smart segments (Today, Tomorrow, Upcoming, Later, Overdue) remain algorithmically sorted — unaffected

## Capabilities

### New Capabilities
- `custom-list-reorder`: Drag-and-drop reordering of tasks within custom task lists, persisted via fractional string sort orders

### Modified Capabilities
*(None — no existing specs change their requirements)*

## Impact

- **Model**: `TaskFlowSchemaV3` with `sortOrder` field, V2→V3 lightweight migration, backfill logic
- **Query**: `ListDetailView` switches from `@Query(sort: \.createdAt, .reverse)` to `@Query(sort: \.sortOrder, .forward)`
- **UI**: `ListDetailView` gains `.onMove`, `moveTask(fromOffsets:toOffset:)` handler
- **Creation**: `ReminderDraftMapper` and `ReminderEditorView` assign initial `sortOrder` on task creation
- **Config**: No new dependencies
