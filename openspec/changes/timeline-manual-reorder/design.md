## Context

Currently the app has two separate ordering regimes:

| View | Sort mechanism | User-reorderable? |
|------|---------------|-------------------|
| List Detail (custom lists) | `sortOrder` (LexoRank string) | Yes — `.onMove` + `.onDrag`/`.onDrop` |
| Today/Tomorrow/Upcoming | Algorithmic: `dueDate` → `createdAt` → `taskKey` | No |
| Lists tab | `sortOrder` (same algorithm) | Yes — `.onMove` |

The LexoRank-style `midpoint(between:and:)` algorithm lives in `SortOrderMidpoint.swift`. Reorder logic (`moveTasks(fromOffsets:toOffset:)`) lives in `DetailViewModel`. The same pattern is duplicated for lists in `ListViewModel.moveLists`.

`sortOrder` is currently a **per-list namespace** — midpoints are computed only among tasks sharing the same `reminderList`. Cross-list `sortOrder` comparisons are accidental (two tasks in different lists have no meaningful order relationship).

## Goals / Non-Goals

**Goals:**
- Users can reorder tasks by drag in Today, Tomorrow, and Upcoming views
- `sortOrder` is the primary sort key in all views (when present), creating a unified ordering model
- The midpoint/widen algorithm is extracted into a shared utility, not duplicated between ViewModels
- New tasks created via quick capture in timeline views get a `sortOrder` consistent with the model
- Existing reorder behavior in list detail views is unchanged

**Non-Goals:**
- Multi-select drag reorder in timeline views (deferred — single-drag only for now)
- Drag-drop nesting/un-nesting in timeline views (parent/child relationships remain managed in list detail)
- Reorder within Lists tab (already works, not affected)
- Per-view or per-segment ordering namespaces (the model is global)

## Decisions

### Decision 1: Global unified ordering (Option A from exploration)

`sortOrder` becomes the universal ordering key for a task. When present, it sorts before any task without one. Within any view, tasks are ordered by `sortOrder` lexicographically. The algorithmic sort (`dueDate` → `createdAt`) becomes a fallback for the edge case where `sortOrder` is `nil`.

**Rationale:** This is the simplest model that unifies all views. A task has one position everywhere. Reordering in Today reorders it in its list too — this is consistent with the mental model that "a task lives in both axes simultaneously."

**Alternatives considered:**
- **Per-view namespace (Option B)**: A separate ordering namespace per timeline view. Rejected because it adds complexity (compound keys, sparse per-view order data) and breaks the unified model. Users would have to reorder the same task in each view independently.
- **Pin-within-sections (Option C)**: Reorder only within algorithmic sections. Rejected as a half-measure that still requires resolving the namespace question.

**Implication for cross-list reorder:** When a user drags a task between two tasks from different lists in a timeline view, the task's new `sortOrder` is a midpoint between neighbors that belong to different namespaces. This changes the task's position within its own list. This is accepted behavior — the user's ordering preference is global.

### Decision 2: Shared `SortOrderReordering` utility

Extract `moveTasks(fromOffsets:toOffset:)` into a standalone utility:

```swift
enum SortOrderReordering {
    static func reorder(
        _ tasks: inout [TaskItem],
        fromOffsets: IndexSet,
        toOffset: Int
    ) {
        // Identical logic to current DetailViewModel.moveTasks
    }
}
```

Both `DetailViewModel` and `ReminderSegmentViewModel` call this utility.

**Rationale:** The algorithm operates on an array — it has no dependency on lists, ViewModels, or views. Extracting it eliminates duplication and ensures consistent behavior across all reorder contexts.

**Alternative considered:** Protocol-based approach (`Reorderable` protocol). Rejected as over-engineering for a single utility.

### Decision 3: Timeline sort key changes to `sortOrder` → fallback

`ReminderSegmentLogic.sortedTasks` changes from:

```swift
tasks.sorted { lhs, rhs in
    (lhs.dueDate, lhs.createdAt, lhs.taskKey)
    < (rhs.dueDate, rhs.createdAt, rhs.taskKey)
}
```

To:

```swift
tasks.sorted { lhs, rhs in
    let lhsOrder = lhs.sortOrder ?? ""
    let rhsOrder = rhs.sortOrder ?? ""
    if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
    // fallback: dueDate → createdAt → taskKey
}
```

**Rationale:** Tasks with explicit `sortOrder` sort by it; tasks without (edge case) fall through to algorithmic sort. Since backfill assigns `sortOrder` to all tasks, the fallback path is rare.

### Decision 4: Quick capture assigns end-of-view sortOrder

When creating a task via quick capture in a timeline view, `assignSortOrder` appends it after all tasks visible in that view (not just tasks in its list).

**Rationale:** If sortOrder is global, a new task should appear at the bottom of the current view. Appending to end-of-list (current behavior) is a subset of this — the list's last task's sortOrder is a proxy for "bottom of view." The algorithm: midpoint between the last visible task's sortOrder and `nil`.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Cross-list side effects surprise users**: Reordering in Today moves a task within its home list, potentially interleaving it between tasks from unrelated lists | Document in release notes. The behavior is consistent with "one position everywhere." A future undo/redo could help. |
| **Existing sortOrder values have no cross-list ordering semantics**: Tasks in different lists have sortOrders like "a" and "m" — when viewed together in a timeline, "a" always sorts before "m" by accident, not intent | This is acceptable. The initial sort order after backfill is deterministic (by `createdAt` which gets assigned sequentially per list). Users establish meaningful order as they drag. |
| **Performance**: Full timeline view re-sorts on every drag (recompute/rebuilt tree) | Already the pattern used in `DetailViewModel.recompute()`. No new cost. |
| **Backfill ambiguity**: Existing tasks have sortOrders computed per-list. After this change, they'll be sorted by these per-list values when viewed together in timeline views, producing effectively random cross-list ordering. | Accept initial state. Ordering crystallizes as users drag. First drag in timeline view triggers the midpoint algorithm which establishes intentional cross-list positions. |

## Open Questions

1. **Should reordering in a timeline view be scoped to tasks within the same section?** (e.g., can you drag a task from "Overdue" into "Today" section via reorder, or does that require rescheduling?) — Current thinking: drag-reorder only changes position within the current filter. Cross-section moves require changing the due date.
2. **Single drag only, or multi-select drag?** — Proposal: single drag for now. Multi-select is already supported in `DetailViewModel.moveTasks` and would be inherited by the shared utility, but timeline UI hasn't implemented multi-select.
3. **Nesting via drag-drop in timeline views?** — Out of scope for now. The parent/child relationship is managed in list detail views. Timeline views show nested subtasks but don't allow creating nesting via drag.
4. **Should the "Smart segments show no reorder affordance" scenario in custom-list-reorder spec be removed or modified?** — It should be removed, replaced by the new timeline-reorder spec.
