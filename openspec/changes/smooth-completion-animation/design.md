## Context

Current completion flow in `TimelineViewModel`:
1. `filteredTasks` excludes completed task
2. `sorted` = remaining tasks (correct order)
3. `recent` = tasks in `justCompleted` set
4. `sortedFlatTasks = sorted + recent` — appends, causing position jump

The List Detail path (`DetailViewModel.computeTasks`) keeps the completed task in its natural `sortOrder` position — no jump issue. Only the Timeline path appends.

## Goals / Non-Goals

**Goals:**
- Completed task stays in its original list position during the 0.6s grace period
- Strikethrough appears on completed task titles with 0.18s animation
- Match Apple Reminders behavior: dim + strikethrough in place → fade out

**Non-Goals:**
- Grace period extended from 0.6s to 1.5s to match Apple Reminders timing
- No changes to the List Detail path
- No new visual effects beyond strikethrough

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Position stability | Sort `justCompleted` tasks alongside `filteredTasks` | Completed task keeps its `dueDate`/`createdAt` — same sort key, same position. No state tracking needed. |
| Strikethrough | `.strikethroke(true, color: .textSecondary)` on title `Text` | Matches Apple Reminders visual. Color matches the dimmed text color. |
| List Detail path | No change needed | `computeTasks()` keeps completed tasks in `justCompleted` within the same `sortOrder` — no position change. |

## Risks / Trade-offs

- None significant. This is a narrow behavioral fix with no architectural impact.
