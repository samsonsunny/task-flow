## Context

Currently `ReminderList` is flat — no hierarchy exists. The `ListsTabView` displays all lists in a single sorted list with the default "Reminders" list pinned first, then alphabetical. There is no concept of list groups, no expand/collapse sections, and no drag-reorder for lists or groups.

The existing `sortOrder` fractional string pattern (used for task drag-reorder in `ListDetailView`) can be reused for both group and list ordering.

## Goals / Non-Goals

**Goals:**
- Add `ReminderListGroup` model with 1:N relationship to `ReminderList`
- Lightweight additive migration from V3 → V4 with no data loss
- ListsTabView displays groups as expandable/collapsible sections
- Groups, lists within groups, and ungrouped lists are all drag-reorderable
- Default "Reminders" list pinned at top, outside any group
- Context menu offers group creation and move-to-group actions
- Expanded/collapsed state persists across app restarts

**Non-Goals:**
- Nested sub-groups (single level only)
- Sidebar group support
- Quick-capture into groups (tasks always go to a concrete list)
- Group creation from the "+" toolbar button (only via context menu)
- Multi-select operations on groups or lists
- Group-level task filtering or aggregated task views

## Decisions

### Decision: SwiftData schema V4 with lightweight migration

Introduce `TaskFlowSchemaV4` containing `ReminderListGroup` and the updated `ReminderList` with an optional inverse. The migration from V3 is lightweight (additive, no data transformation) because the new relationship is optional and there are no required fields.

### Decision: Fractional string sortOrder for both groups and lists

Reuse the same `midpoint(between:and:)` / `widen(_:)` already implemented in `ListDetailView` for task reorder. Extract these into a shared utility so both `ReminderListGroup.sortOrder` and `ReminderList.sortOrder` can use them.

### Decision: @AppStorage for expand/collapse state

Each group's expanded state persists via `UserDefaults` using key `"list-group-expanded-\(group.persistentModelID)"`. Default is `true` (expanded). This avoids adding persistence state to the SwiftData model and keeps schema migration trivial.

### Decision: Custom drag-drop via onDrag/onDrop

`List.onMove` does not handle cross-section or cross-group drops well. Instead, use `.onDrag` with `NSItemProvider` carrying the list/group `persistentModelID`, and `.onDrop` on each section (group section, ungrouped section) to handle insertion at position. This handles:
- Reordering groups among themselves
- Reordering lists within a group
- Moving lists between groups
- Moving lists to/from ungrouped

### Decision: Context menu for group operations

Use SwiftUI `.contextMenu` on `ReminderList` rows (excluding the default list) to provide "Create New Group" and "Move to Group → [submenu]". This avoids cluttering the toolbar and keeps group creation tied to the list being moved.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Cross-section drag-drop is fragile in SwiftUI | Implement a clear drop zone per section with visual highlight; test on device |
| Large number of groups/lists could make the Lists tab scroll-heavy | Expand/collapse keeps the view manageable; groups default to expanded but user can collapse |
| V3 → V4 lightweight migration may fail if SwiftData schema inference is inconsistent | Pin the schema version explicitly in `VersionedSchema`; test migration from a V3 store |
| Drag-reorder during ongoing edit/capture of a list name | Lists tab doesn't have inline editing — list names are set at creation. No conflict |
