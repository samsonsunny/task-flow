# Concept: Today & Completed Tasks

**Surface:** Cross-domain attention (Today) and the completed archive.
**Code:** `TaskFlow/Features/Today/`, `TaskFlow/Features/Completed/`

## Purpose

Today is the app's attention surface. It collects overdue and due-today tasks from both permanent domains, Work and Personal, into one list. There are no Tomorrow or Upcoming tabs: undated and future tasks stay in their domain until they become due.

Completed is a low-frequency archive reached from More.

## Code map

| File | Role |
|---|---|
| `TaskFlow/Features/Today/TodayTaskListView.swift` | `@Query` + NavigationStack for Today |
| `TaskFlow/Features/Today/TodayViewModel.swift` | Sections, optional domain filter, completion/undo |
| `TaskFlow/Features/Completed/CompletedView.swift` + `CompletedViewModel.swift` | Recent-completions archive under More |
| `TaskFlow/Views/Components/TaskRowView.swift` | Shared row used by Today and domain views |

The old `Features/Tasks/Timeline` engine and `TodayView` / `TomorrowView` / `UpcomingView` wrappers are legacy and not part of root navigation. Do not reintroduce them as tabs.

## Responsibilities of TodayViewModel

### Derived state (`update(groups:allTasks:now:)`)
- Splits incomplete tasks into `overdue` and `today` sections.
- Excludes completed tasks except during the undo window.
- Builds optional domain filter options (All, Work, Personal).
- Sorts by due date, then creation date, then task ID.

### Mutations
- `toggleCompletion(for:)` with undo support.
- `delete(task:)`.
- `selectFilter(_:)` for the optional domain filter.

### Time correctness
- The view passes `now` into `update`; overdue membership is time-dependent.
- Date-only tasks compare by day; timed tasks compare by exact time.

## Responsibilities of CompletedViewModel

### Derived state
- 30-day cutoff.
- Grouping into Today / Yesterday / This Week / Earlier.

### Mutations
- `uncomplete(_:)` / `beginUncomplete(_:)` restores the task to its list and reschedules notifications when appropriate.
- `delete(_:)` cancels notifications.
- Bulk uncomplete/delete.

## Invariants worth preserving

1. **Today is cross-domain.** Never split Today into per-domain or per-time tabs.
2. **Today contains only overdue + due today.** Future and undated tasks belong to their Work/Personal domain.
3. **Rows carry domain/list context** when the view is unfiltered, because tasks from both domains are mixed.
4. **Notification lifecycle mirrors task lifecycle.** Completing or deleting cancels; un-completing or saving with a time schedules.
5. **Explicit `update()` after every mutation** — property-only changes are invisible to `onChange` because models compare by `persistentModelID`.
6. **Undo is visual state.** A just-completed task stays visible during the undo window but is excluded from badges and persistence logic as completed.
