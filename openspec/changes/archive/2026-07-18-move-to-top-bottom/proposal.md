## Problem

In list views with 30+ tasks, dragging a task from position 30 to position 1 is tedious and error-prone on mobile. There's no quick way to prioritize a task without precision dragging.

## Proposal

Add "Move to Top" and "Move to Bottom" context menu actions for tasks in list views. Single tap moves the task to the top or bottom of its current ordering context.

### Scope

- List views (DetailView) — roots and children
- Today/Tomorrow views — NOT in scope (lists are short, drag is fine)
- Upcoming view — NOT in scope

### Behavior

**Root task:**
- "Top" → sortOrder before all roots → moves to top of list
- "Bottom" → sortOrder after all roots → moves to bottom of list

**Child task:**
- "Top" → sortOrder before all siblings → moves to top of parent's children
- "Bottom" → sortOrder after all siblings → moves to bottom of parent's children

Tree structure never changes. Children stay under their parent.

### Context Menu Layout

```
Today
Tomorrow
Later
Schedule
───────────
Move to Top         ↑
Move to Bottom      ↓
Move to List →
───────────
Delete
```

Three sections separated by dividers:
1. Time actions (Today, Tomorrow, Later, Schedule)
2. Reorder + relocate (Move to Top, Move to Bottom, Move to List)
3. Destructive (Delete)

### Visibility

- Show for all tasks in list views (roots and children)
- Hide when the list/sibling group has ≤1 task
- Hidden in daily views (Today/Tomorrow) — reorder uses drag there

## User Story

As a user with long lists, I want to quickly move a task to the top or bottom of my list with a single tap, without dragging across 30+ rows.

## Technical Approach

### ViewModel (DetailViewModel)

Two new methods using the existing midpoint algorithm:

- `moveToTop(task:)` — computes `midpoint(between: nil, and: firstSibling.sortOrder)`
- `moveToBottom(task:)` — computes `midpoint(between: lastSibling.sortOrder, and: nil)`

Where "siblings" = roots for root tasks, or parent's children for child tasks.

### View (TaskRowView)

Two new optional closures:
- `onMoveToTop: (() -> Void)?`
- `onMoveToBottom: (() -> Void)?`

Rendered as buttons in the context menu, conditionally shown.

### View (DetailView)

Wire the closures in `taskListRow()`:
- Get the task's siblings (roots or parent's children)
- Only provide closures if siblings.count > 1
- Call `viewModel?.moveToTop(task:)` or `viewModel?.moveToBottom(task:)`
