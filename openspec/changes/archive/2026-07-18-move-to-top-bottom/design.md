## Context

List views with 30+ tasks make drag-and-drop reordering painful. The midpoint algorithm for `sortOrder` already supports computing extreme positions (before all, after all). The context menu already has a `Divider()` pattern.

## Goals / Non-Goals

**Goals:**
- "Move to Top" / "Move to Bottom" in context menu for list views
- Single tap, no dragging
- Works for both root and child tasks
- Context menu with three sections separated by dividers

**Non-Goals:**
- Daily views (Today/Tomorrow) — out of scope
- Upcoming view — out of scope
- Swipe actions for reorder — out of scope

## Decisions

### Decision 1: Scope is sibling-aware

"Move to Top" on a child moves to top of its siblings, not the entire list. This preserves the tree structure. The user intuitively expects a child to stay under its parent.

### Decision 2: Use existing midpoint algorithm

`moveToTop(task:)` computes `midpoint(between: nil, and: first.sortOrder)`.
`moveToBottom(task:)` computes `midpoint(between: last.sortOrder, and: nil)`.

Same algorithm as `moveTasks()`, just targeting extremes.

### Decision 3: Hide when ≤1 task in context

If the task is the only root or only sibling, "Move to Top/Bottom" is meaningless. The closures should be nil in that case.

### Decision 4: Context menu sections

```
Section 1: Time actions (Today, Tomorrow, Later, Schedule)
Divider
Section 2: Reorder + relocate (Move to Top, Move to Bottom, Move to List)
Divider
Section 3: Destructive (Delete)
```
