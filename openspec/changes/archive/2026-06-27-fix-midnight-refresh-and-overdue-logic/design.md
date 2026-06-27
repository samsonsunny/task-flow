## Context

Two independent fixes in one change:

**Fix 1 — Midnight refresh:** `refreshNow()` in both ViewModels does partial updates. Changing them to full recomputation is a one-liner each.

**Fix 2 — Time-aware overdue:** The `.overdue` filter only compares `startOfDay`. Tasks with a time component past their due time but within the same day are missed. Apple Reminders compares the exact time for timed reminders.

## Goals / Non-Goals

**Goals:**
- Visible tab refreshes content when day rolls over (timer triggers full recompute)
- Tasks with `hasTime` show as overdue when their exact due time passes
- All consumers of `.overdue` segment filtering benefit automatically (sidebar badge count, badge, timeline)

**Non-Goals:**
- No UI changes
- No model changes
- No new timer or polling — reuses existing 60s `refreshTimer`

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| refreshNow approach | Delegate to `update()` / `recompute()` | Reuses existing computation. No new code paths. |
| Time-aware overdue | `dueDate < now` for `hasTime`, `startOfDay < todayStart` for date-only | Matches Apple Reminders behavior exactly. |
| Duplicate change in sidebar? | Not needed — `ReminderSegmentLogic.filteredTasks(tasks:for:.overdue)` is shared | Sidebar count, badge count, and segment view all use the same logic. |

## Risks / Trade-offs

- [Behavior change for time-aware overdue] → This is a stricter definition — some tasks that were "Today" will become "Overdue" mid-day. Users may notice more tasks in the overdue section. This matches the expected behavior from Reminders/Things/Todoist.
