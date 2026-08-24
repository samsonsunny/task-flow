# Concept: Task Segments & Completed Tasks

**Axis:** Attention — what the user should act on now, next, and later.
**Consolidated from (archived):** `mvvm-reminder-segment.json`, `mvvm-completed-view.json`

## Purpose

The attention-axis screens slice tasks by date: Today (including overdue), Tomorrow, Upcoming (grouped by day/month), Later, Overdue, plus the Completed view (recent 30 days). One shared timeline engine renders all segments; a dedicated ViewModel handles the completed archive.

## Code map

| File | Role |
|---|---|
| `TaskFlow/Features/Tasks/Timeline/TimelineView.swift` | Shared segment renderer |
| `TaskFlow/Features/Tasks/Timeline/TimelineViewModel.swift` | All segment logic (`@Observable`) |
| `TaskFlow/Features/Tasks/Timeline/TimelineSections.swift` | Section building/sorting helpers |
| `TaskFlow/Features/Tasks/Timeline/TimeSegments.swift` | Time-of-day segmentation + subtitles |
| `TaskFlow/Features/Tasks/TodayView.swift`, `TomorrowView.swift`, `UpcomingView.swift` | Thin per-tab views holding `@Query` |
| `TaskFlow/Features/Completed/CompletedView.swift` + `CompletedViewModel.swift` | Recent-completions archive |

## Responsibilities of TimelineViewModel

### Derived state (recomputed in `update(tasks:lists:now:collapsedTasks:)`)
- Segment filtering, sorting, grouping across all 5 segments (Today, Tomorrow, Upcoming, Later, Overdue) — delegates to `ReminderSegmentLogic` / `TaskUIModel` helpers.
- `flatNodes(for:collapsedTasks:)` — parent-child tree flattened for display honoring collapse.
- Quick-capture context: `resolvedQuickCaptureList()`, `captureDateHint(activeCaptureDate:)`, `shouldShowDueDate(for:)`.
- Overdue count recomputed via `refreshNow()` on a view-owned timer so midnight rollover is caught.

### Mutations
- **Completion:** `toggleCompletion(for:)` — haptic, justCompleted animation tracking, notification cancellation.
- **Quick capture:** `commitQuickCapture(text:notes:captureDate:)` creates the task with segment-appropriate contextual dates; `openQuickCaptureEditor(...)` hands off to full editor.
- **Scheduling:** `scheduleTask(_:dueDate:hasTime:)`; reschedule shortcuts `rescheduleToToday/Tomorrow/NextDay/NextWeek/ThisWeekend/None`.
- **Move/delete:** `moveTask(_:to:)`, `delete(task:)` (cancels notifications).
- **Manual reorder:** `moveTasks(fromOffsets:toOffset:in:orderKey:)` with per-day order persisted via `readDailyOrder/writeDailyOrder`.
- **Bulk variants:** `bulkReschedule*`, `bulkMoveToList`, `bulkToggleCompletion`, `bulkDelete`, `bulkSetPriority`.

## Responsibilities of CompletedViewModel

### Derived state
- 30-day cutoff filter (`update(tasks:now:)`).
- Date grouping into Today / Yesterday / This Week / Earlier.

### Mutations
- `uncomplete(_:)` / `beginUncomplete(_:)` — restores task to its pre-completion bucket and **reschedules its notification**.
- `delete(_:)` — cancels notification.
- Bulk: `bulkUncomplete`, `bulkDelete`.

## Invariants worth preserving

1. **Notification lifecycle mirrors lifecycle events.** Completing or deleting cancels; un-completing or saving with a time schedules. Never bypass the VM.
2. **Midnight correctness.** Segment membership is time-dependent; the refresh timer + `refreshNow()` must keep running in the view.
3. **Contextual quick capture dates.** A task captured in "Tomorrow" lands tomorrow; captured without time → no reminder. The VM owns this mapping, not the view.
4. **Explicit `update()` after every mutation** — property-only changes are invisible to `onChange` (`persistentModelID` equality).
5. **Completed window is fixed at 30 days** by design; older completions are out of scope for this screen.

## History

Originally two separate refactors (June 2026): ReminderSegmentDetailView (~714 lines → VM) and CompletedView (~181 lines → VM). Since then the code has grown bulk operations, Next Day/Weekend reschedules, and daily-order persistence — none of which existed in the PRDs.
