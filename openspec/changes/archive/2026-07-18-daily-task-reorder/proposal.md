## Problem

Users cannot reorder tasks in Today/Tomorrow views. Task order is entirely determined by date-based sorting (dueDate → createdAt → taskKey). There's no way to say "I want to do this one first today" without changing due dates.

## Proposal

Add drag-to-reorder for **root/parent tasks only** in Today and Tomorrow views. The ordering is stored in UserDefaults as ordered task ID arrays (one per segment), completely independent of the `sortOrder` property used in List views.

### Scope

- Today view: reorder root tasks within the date section
- Tomorrow view: reorder root tasks within the date section
- Parent tasks only — children stay nested under their parent
- Overdue section in Today: separate ordering from Today's main tasks
- Upcoming view: not in scope (future iteration)

### Out of Scope

- Reordering in Upcoming view
- Reordering child/subtasks independently
- Affecting List view sort order (`sortOrder` property untouched)
- Schema changes

## User Story

As a user, I want to drag tasks in my Today/Tomorrow view to prioritize what I work on first, without changing where those tasks appear in their parent lists.

## Technical Approach

### Storage

UserDefaults with two keys:

```
"daily-order-today": ["uuid-3", "uuid-1", "uuid-5"]
"daily-order-tomorrow": ["uuid-7", "uuid-2"]
```

Ordered arrays of `TaskItem.persistentModelID` strings. Tasks not in the array sort to the end by default date logic.

### Sort Logic

Modified `ReminderSegmentLogic.sortedTasks()` in `TimeSegments.swift`:

1. Position in UserDefaults array (if present) — lowest index first
2. `dueDate` (existing fallback)
3. `createdAt` (existing fallback)
4. `taskKey` (existing fallback)

### ViewModel Changes

`TimelineViewModel` gains:
- `moveTasks(fromOffsets:toOffset:in:)` — writes new order to UserDefaults
- Reads UserDefaults on `update()` to compute sorted order

### View Changes

`ReminderSegmentDetailView` (shared by Today/Tomorrow):
- `.onMove` on root task list in each segment
- Overdue section gets its own `.onMove` with separate UserDefaults key

## Why UserDefaults (Not Schema)

- No migration needed (V8 stays current)
- Same pattern as group expand/collapse state
- Order is a UI preference, not core data — acceptable to lose on reinstall
- Tasks themselves survive (SwiftData); only reorder resets
