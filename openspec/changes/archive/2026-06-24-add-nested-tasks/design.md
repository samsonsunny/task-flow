## Context

TaskFlow uses a flat `TaskItem` SwiftData model with no parent-child relationships. Tasks are displayed in a flat `ForEach` in both `ListDetailView` and `ReminderSegmentDetailView`. The `TaskRowView` component renders a single row with title, notes, metadata, and a completion button.

The app has 3 schema versions (V1→V2→V3) managed through `SchemaMigrationPlan`. The next migration (V4) will add the `parentTask` relationship.

## Goals / Non-Goals

**Goals:**
- Add a self-referencing `parentTask` relationship to `TaskItem` enabling arbitrary-depth task nesting
- Indented, collapsible subtask display in `ListDetailView`
- Independent task display in segment views (Today/Upcoming/Later)
- Cascade delete and cascade completion on parents
- Drag-and-drop reparenting in list views
- Subtask creation from the editor

**Non-Goals:**
- Subtask-specific UI in segment views (subtasks appear flat)
- Completion progress indicators (e.g., "3/5 done" badges)
- Subtask count in sidebar or list headers
- Subtask search/filtering
- Drag-and-drop across different lists (only within the same list)

## Decisions

### Decision 1: Self-referencing relationship on TaskItem
A single `TaskItem` with `@Relationship(inverse: \TaskItem.subtasks)` for `parentTask` and `@Relationship` for `subtasks`.

Rationale:
- Avoids a separate model (unnecessary complexity for Apple-style subtasks)
- Subtasks are full `TaskItem` instances with all fields (due dates, priorities, tags, notifications)
- SwiftData manages the inverse automatically (no orphan subtasks from missing deletes)
- Schema migration V3→V4 with `.lightweight` (additive relationship, no data loss)

Alternatives considered: Separate `ChecklistItem` model — rejected because Apple Reminders uses full task instances as subtasks, and users expect subtasks to have the same capabilities.

### Decision 2: Flatten-hierarchy query strategy for segment views
Segment views (`ReminderSegmentDetailView`) query ALL tasks (including subtasks) as a flat array. The existing `ReminderSegmentLogic.filteredTasks()` works unchanged — subtasks with their own due dates appear naturally in the correct segment.

Rationale:
- Minimal changes to existing filtering/sorting code
- Subtasks without due dates are hidden from segment views, matching Apple's behavior
- Avoids complex recursive filtering

Trade-off: If a parent is due Friday and a subtask is due Tuesday, they appear independently. The parent is not shown as "collapsible with subtask" in segment views — this matches Apple's Reminders behavior.

### Decision 3: Recursive rendering with depth tracking
`TaskRowView` becomes a `TaskNodeView` that recursively renders children. Each level tracks `depth` (integer) for indentation. A `collapsedState` dictionary (`[PersistentModelID: Bool]`) is stored at the list level.

Rationale:
- SwiftUI's `ForEach` doesn't support recursive structures natively
- Each node owns its children, making collapse/expand scoped correctly
- Depth-based indentation is simple and avoids GeometryReader overhead

Alternative considered: Flatten all tasks with a computed `depth` property and use single-level `ForEach` — rejected because collapse state management becomes complex and animation is harder to get right.

### Decision 4: Sort order among siblings
Existing `sortOrder` (string-based fractional indexing) handles ordering within siblings. When reparenting, the subtask inherits the parent's sort-order namespace. The `midpoint`/`widen` utility already exists.

Rationale:
- Reuses proven ordering mechanism
- Drag-and-drop reordering and reparenting both use the same `midpoint` algorithm

### Decision 5: Cascade completion, not cascade auto-complete
Completing a parent sets `isCompleted = true` and `completionDate = Date()` on all descendants. Completing all subtasks does NOT auto-complete the parent.

Rationale:
- Matches Apple Reminders exactly
- Avoids surprising the user ("why did my parent task get completed?")
- Simple to implement: recursive method on `TaskItem`

### Decision 6: Cascade delete
Deleting a parent task deletes all descendants.

Rationale:
- Matches Apple Reminders
- No orphan tasks
- SwiftData's `@Relationship` can cascade delete (or we do it manually in `modelContext.delete`)

## Risks / Trade-offs

- **Performance with deep nesting**: Each parent expansion triggers a fetch of its children. With SwiftData's lazy relationships, this should be acceptable for typical usage (depths < 5, subtask counts < 50). If needed, prefetching can be added.
- **Unbounded recursion in UI**: SwiftUI recursive views with `@ViewBuilder` can hit stack limits past ~10 levels. Mitigation: flatten to a single level in the `List` body and use `List`-safe indentation instead of true recursion for deep hierarchies.
- **Drag reparenting ambiguity**: When dragging over a task row, does the drop target mean "make this a sibling" or "make this a child"? Mitigation: Use visual indicators — dropping on the top half of a row inserts as sibling, bottom half as child (matching Reminders.app).
- **Migration**: Adding `parentTask` as an optional relationship is a lightweight migration. No data loss. Subtasks will only exist post-migration.
