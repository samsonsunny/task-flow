## Context

Tasks in custom lists (`ListDetailView`) are currently sorted by `createdAt` descending — pure capture order. Users have no way to prioritize or re-sequence tasks. Smart segments (Today, Tomorrow, Upcoming, Later, Overdue) use algorithmic sorting by `dueDate` → `createdAt` descending and are not affected by this change.

The existing data model (`TaskFlowSchemaV2`) has no `sortOrder` field. A V3 schema with lightweight migration is needed.

## Goals / Non-Goals

**Goals:**
- Users can drag tasks to reorder them within any custom list
- Reordered position persists across app restarts
- Only the moved task's `sortOrder` string is updated per drag (no full-list re-index)
- New tasks appear at the end of the list
- Rare edge case (exhausted alphabet between adjacent pairs) handled locally without full rebalance

**Non-Goals:**
- Smart segment reordering (Today, Tomorrow, Upcoming, Later, Overdue remain algorithmic)
- List-level reordering (sidebar list order is unchanged)
- Cross-list drag-and-drop (moving tasks between lists remains via context menu / editor)

## Decisions

### 1. Fractional string ordering (LexoRank-style)

Use `String?` sortOrder with a lexicographic midpoint algorithm, rather than `Int` or `Double`.

**Rationale:**
- `Int`: requires re-indexing every item on every drag (defeats the "hack" goal)
- `Double`: precision decays with repeated inserts between same pair; eventual rebalance is unavoidable
- `String`: no precision ceiling — strings grow by ~1 char per ~50 inserts. Midpoint between any two strings always exists. One write per drag.

**Algorithm:**
```swift
func midpoint(between lower: String?, and upper: String?) -> String {
    // Alphabet: a-z (26 chars, indices 0-25)
    // nil lower → empty string (index -1, lexicographically minimum)
    // nil upper → unbounded (index 26)
    // Precondition: lower < upper when both non-nil
    let low = lower ?? ""
    var result = ""
    for i in 0... {
        let lv = i < low.count ? charValue(low[i]) : -1
        let uv = i < (upper?.count ?? 0) ? charValue(upper![i]) : 26
        if uv - lv > 1 {
            result += charFrom(lv + (uv - lv) / 2)
            return result
        }
        result += charFrom(lv)
    }
}
```

### 2. Local 3-item widen for adjacency exhaustion

When repeated inserts between the same pair hit the `lv=-1, uv=0` adjacency case (e.g., between `"f"` and `"fa"`), the algorithm cannot produce a valid string. Mitigation: re-index only the 3 adjacent items.

**Trigger condition:** `uv - lv == 1 && lv == -1 && uv == 0` at any position, with both bounds non-nil.

**Action:** Read the moved item's new predecessor and successor, widen one of them by appending `"z"`, then recompute. Exactly 3 writes. This case is extremely rare in practice.

### 3. V2 → V3 lightweight SwiftData migration

New `sortOrder: String?` attribute on `TaskItem`. Backfill existing tasks in each custom list with sequential single-letter values (`"a"`, `"b"`, `"c"`, ...) based on current `createdAt` order.

**Rationale:** Lightweight migration avoids custom migration code. Sequential letters give clean starting positions with room for insertions.

### 4. Query change in ListDetailView

```swift
// Before:
@Query(sort: \TaskItem.createdAt, order: .reverse)
// After:
@Query(sort: \TaskItem.sortOrder, order: .forward)
```

Tasks with `nil` sortOrder (should not exist post-migration, but safe fallback) sort to the end via a computed property.

### 5. .onMove integration

SwiftUI's native `.onMove` modifier provides `IndexSet` and destination offset. The handler:
1. Identifies the dragged items
2. Removes them from the array
3. Inserts at target position
4. For each dragged item (in order), calls `midpoint(between: predecessor, and: successor)`
5. Updates only the dragged items' `sortOrder` in the model context

Multi-drag: items are chained — each subsequent item's midpoint is computed relative to the previous dragged item's new sortOrder.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **String growth**: repeated inserts between same pair grow strings unboundedly | In practice, inserts spread across the list. 100 consecutive inserts between same pair yields ~100 char strings — negligible storage. If it becomes a concern, add a periodic rebalance (re-index every item to new short strings). |
| **Adjacency exhaustion**: no valid midpoint between two bounds | Local 3-item widen handles it. Falls back to re-indexing only the 3 affected items, not the full list. |
| **SortOrder nil after migration**: corrupted data or race condition | Computed property falls back to `createdAt` descending for nil values. |
| **Confusion with smart segments**: user expects DnD everywhere | Smart segments explicitly excluded. UI has no reorder affordance (no drag handle) on smart segment rows. |
