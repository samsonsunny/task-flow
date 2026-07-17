## Context

Groups already have `sortOrder: String?` on `ReminderListGroup` and are fetched sorted by it. The `midpoint()` sort algorithm is proven across list reorder and task reorder. The only gap is wiring `.onMove` on the groups section and adding the ViewModel method.

## Goals / Non-Goals

**Goals:**
- Users can drag to reorder groups in the Later tab
- Order persists via `sortOrder` using the existing midpoint algorithm
- Inbox and ungrouped lists stay pinned above groups

**Non-Goals:**
- Moving lists between groups via drag (context menu handles this)
- Reordering the Inbox or ungrouped lists section

## Decisions

### Decision 1: Add `.onMove` to the groups `ForEach`

The groups are already rendered in a `ForEach` inside `ListsTabView`. Adding `.onMove` to this `ForEach` enables drag reorder. The handler calls `viewModel?.moveGroups(fromOffsets:toOffset:)`.

### Decision 2: `moveGroups` follows the same pattern as `moveLists`

```
1. Get the sorted groups array
2. Compute new sortOrder for each moved group using midpoint
3. Save to modelContext
```

Same algorithm, different entity. ~20 lines.

### Decision 3: Group order is global, not per-section

Groups share a single `sortOrder` space. The order is the order — there's no "per-section" ordering since groups are a flat list.
