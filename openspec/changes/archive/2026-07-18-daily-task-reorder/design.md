## Context

Today/Tomorrow views sort tasks by `dueDate → createdAt → taskKey`. Users cannot manually reorder tasks within a day segment. The goal is to add drag-to-reorder for root tasks only, stored in UserDefaults, independent of the List view's `sortOrder`.

## Goals / Non-Goals

**Goals:**
- Users can drag root tasks to reorder in Today and Tomorrow views
- Order persists across app launches via UserDefaults
- Overdue section in Today has its own independent ordering
- Children stay nested under their parent (no child-level reorder)

**Non-Goals:**
- Upcoming view reordering (future iteration)
- Child/subtask reordering
- Affecting List view sort order
- Schema changes

## Decisions

### Decision 1: UserDefaults stores ordered task ID arrays

Two keys per segment:
- `"daily-order-today"` → `[String]` of task IDs
- `"daily-order-tomorrow"` → `[String]` of task IDs
- `"daily-order-overdue"` → `[String]` of task IDs

Same pattern as group expand/collapse state. Tasks not in the array sort to the end by default date logic.

### Decision 2: `sortedTasks()` gains an optional `customOrder` parameter

The existing sort function in `TimeSegments.swift` gets an additional parameter:

```
static func sortedTasks(
    _ tasks: [TaskItem],
    for segment: ReminderSegment,
    customOrder: [String]? = nil,
    calendar: Calendar = .current
) -> [TaskItem]
```

When `customOrder` is provided, tasks whose IDs are in the array sort by their index. Tasks not in the array fall through to the existing date-based sort.

### Decision 3: ViewModel reads UserDefaults on each `update()`

`ReminderSegmentViewModel.update()` reads the UserDefaults array for the current segment and passes it to `sortedTasks()`. This ensures the view always reflects the persisted order.

### Decision 4: `.onMove` on the root task ForEach

The `todayLikeContent()` method renders `flatContent()` inside a `Section`. Adding `.onMove` to the `ForEach` in `flatContent()` enables drag reorder. The handler calls a new ViewModel method that:
1. Gets the current sorted root task IDs
2. Computes the new order
3. Writes to UserDefaults

### Decision 5: Overdue gets its own `.onMove`

The overdue `Section` in the view body gets its own `.onMove` with the `"daily-order-overdue"` key, separate from the main Today ordering.
