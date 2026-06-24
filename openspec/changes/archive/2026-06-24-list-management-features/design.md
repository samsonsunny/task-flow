## Context

Lists are currently managed in `ListsTabView` — a simple list with NavigationLinks to `ListDetailView`. The `ReminderList` model has `name`, `createdAt`, and `reminders`. Lists sort with "Reminders" pinned first, then alphabetically. There is no rename, delete, or reorder capability.

The existing midpoint algorithm in `SortOrderMidpoint.swift` already handles fractional string sort order for tasks within lists. The same algorithm can be reused for list-level sorting.

## Goals / Non-Goals

**Goals:**
- Users can rename any list except the protected "Reminders" list via context menu → alert
- Users can delete any list except "Reminders" via context menu → confirmation with two cascade options
- Delete offers "Move tasks to Reminders" (re-parent) and "Delete All Tasks" (cascade)
- Users can drag-reorder all lists (including "Reminders") in `ListsTabView`
- List order persists across app restarts
- Only the moved list's sortOrder is updated per drag (one write, no full re-index)

**Non-Goals:**
- Cross-device list order sync (app is local-only)
- List reordering in any view other than `ListsTabView` (no sidebar exists)
- Batch operations (rename/delete/reorder multiple lists at once)
- Protected list configurability ("Reminders" is hard-coded as protected)

## Decisions

### 1. Same midpoint algorithm for list reorder

Reuse `midpoint(between:and:)` and `widen(_:)` from `SortOrderMidpoint.swift` for list-level ordering. The algorithm is identical — fractional string encoding with local 3-item widen for adjacency exhaustion.

**Rationale:** No new algorithm needed. The same edge-case handling and performance characteristics apply.

### 2. Create V4 schema with `sortOrder` (lightweight migration)

Add `sortOrder: String?` to `ReminderList` in a new `TaskFlowSchemaV4`. Add a V3→V4 lightweight migration stage to the migration plan. The `typealias ReminderList` and `ModelContainer` init are updated to point to V4.

**Rationale:** SwiftData requires a schema version bump when changing models within a `VersionedSchema`. Adding a field to the existing V3 schema causes a `loadIssueModelContainer` error. V4 is a lightweight migration — no custom migration code needed. Existing data is preserved.

### 3. List query change in ListsTabView

```swift
// Before:
private var sortedLists: [ReminderList] {
    allLists.sorted { lhs, rhs in
        if lhs.name == ReminderDefaults.defaultListName { return true }
        if rhs.name == ReminderDefaults.defaultListName { return false }
        return lhs.name.localizedCompare(rhs.name) == .orderedAscending
    }
}

// After:
@Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
```

New lists created without a sortOrder get `nil` — the query sorts them first (nil sorts before strings in SwiftData). To place them at the end, a computed property or initial sortOrder assignment on creation handles this.

**Decision:** Assign initial `sortOrder = midpoint(between: lastList.sortOrder, and: nil)` on creation, same pattern as task creation. This appends at the end.

### 4. Delete cascade: two explicit options

When deleting a list, the confirmation alert shows two buttons:
- **"Move tasks to Reminders"** (non-destructive): iterates list's tasks, sets each `task.reminderList` to the "Reminders" list, then deletes the list itself.
- **"Delete All Tasks"** (destructive, red tint): deletes tasks then the list.

Both are explicit user choices. No implicit cascade.

**Rationale:** Users should never lose tasks by accident. Re-parenting is the recommended safe default. Cascade is available for users who explicitly want to clean up.

### 5. Context menu on list rows in ListsTabView

`ListsTabView` uses `.contextMenu` modifier on each list row with conditional options based on whether the list is protected:

```
┌──────────────────────┐
│ Rename               │  ← only if list.name != "Reminders"
│ Delete List          │  ← only if list.name != "Reminders"
└──────────────────────┘
```

Rename presents an alert with a text field pre-filled with the current name. Delete presents a confirmation alert with the two cascade options.

### 6. Backfill sortOrder for existing lists

On first launch after the update, all existing `ReminderList` entries without a `sortOrder` receive one based on their current display order (the existing "Reminders" first + alphabetical sort). This ensures existing users see the same order initially, then can customize.

**Rationale:** Backfill prevents all lists from appearing in undefined order on first launch after update.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Data loss from delete**: User accidentally deletes list + tasks | Two-step flow: context menu → confirmation with explicit choice. "Move to Reminders" is the first/non-destructive option. |
| **sortOrder nil on existing lists**: All lists sort to undefined position after update | Backfill on first launch assigns sortOrder based on current display order. Nil-tolerant query fallback. |
| **Protected list bypass**: Setting `ReminderDefaults.defaultListName` to something other than "Reminders" would change which list is protected | Protection check is hard-coded against the string `ReminderDefaults.defaultListName`, which is `"Reminders"`. If the constant changes, protection follows. Acceptable for current scope. |
| **String growth on sortOrder**: Same exhaustion concern as task ordering | Same mitigation — practical inserts spread across positions. Local 3-item widen handles adjacency exhaustion. |
