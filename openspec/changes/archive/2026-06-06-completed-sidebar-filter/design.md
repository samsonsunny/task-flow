## Context

Completed tasks are invisible in the current app. Every smart filter (`ReminderSegmentLogic.filteredTasks`) guards with `guard !isCompleted`, and `ListDetailView` filters with `$0.isCompleted != true`. The only way a task leaves this state is through `toggleCompletion` which sets `isCompleted = false` and clears `completionDate` — but there's no UI to reach that code path for an already-completed task.

The existing `ReminderSegmentDetailView` is designed around actionable tasks: quick-capture, FAB, swipe-to-schedule, swipe-to-move. Repurposing it for a read-only completed view would require conditional complexity throughout the view.

## Goals / Non-Goals

**Goals:**
- Add a "Completed" smart filter in the sidebar under the existing smart filters
- Show recently completed tasks grouped by completion date
- Provide swipe-to-un-complete as the primary row action
- Task reappears in its original smart filter (Today/Tomorrow/Upcoming/Later) based on its `dueDate`
- Limit the view to recent completions to keep it focused as a safety net

**Non-Goals:**
- Not adding "Completed" as a tab in `FilterDetailView`/`SmartFilterTabbedView`
- Not adding quick-capture, FAB, or swipe-to-schedule actions
- Not building a full productivity dashboard or completion history browser
- Not adding count badges in the sidebar for completed tasks
- Not changing the data model (`TaskItem.isCompleted` and `TaskItem.completionDate` are sufficient)
- Not modifying `ReminderSegment` enum or `ReminderSegmentLogic`

## Decisions

### Decision 1: Standalone CompletedView over extending ReminderSegment

**Chosen:** Add `case completed` to `AppNav` only, and create a standalone `CompletedView`.

**Rationale:** `ReminderSegmentDetailView` is tightly coupled to the "actionable tasks" paradigm — it has quick-capture, FAB, swipe-to-schedule actions, and contextual date logic. Forcing a completed view into this template would require conditionals throughout (hide quick-capture, hide FAB, disable swipe actions, override empty state). A standalone view is simpler, more maintainable, and naturally expresses the different interaction model.

**Alternatives considered:**
- Extending `ReminderSegment` with `case completed`: Would touch every switch in the enum (title, icon, tintColor, usesGroupedSections, subtitle, emptyTitle, emptyMessage) plus require conditional branches in the detail view. Too much incidental complexity.
- Using `ListDetailView` with a filter: Designed for list-scoped tasks, not cross-list aggregation. Wrong abstraction.

### Decision 2: Grouped by completion date, flat layout

**Chosen:** Group tasks by completion date using `TaskItem.completionDate`, displayed in a plain `List` with `Section` headers (Today, Yesterday, This Week, Earlier).

**Rationale:** Grouping by completion date gives the user temporal context for when they completed things. Flat layout (not the dated-section system used by Upcoming) keeps the view simple and focused on the un-complete action.

### Decision 3: Time window of 30 days

**Chosen:** Show tasks completed within the last 30 days.

**Rationale:** The primary use case is a safety net for accidental completions and re-surfacing recently completed tasks. Older completions are unlikely to need un-completing and would add visual noise. 30 days is a generous window for catching mistakes.

**Alternatives considered:**
- "Last 50 completions" (no time limit): Could miss very recent tasks if many were completed in a short period.
- No limit: Risk of thousands of completed tasks accumulating over time.
- 7 days: Might be too short — users might realize a mistake after a week.

### Decision 4: Row appearance shows return destination

**Chosen:** Each task row displays the task title (dimmed/strikethrough) and a subtle indicator of where it will reappear upon un-complete (e.g., "Today", "Overdue", "Later").

**Rationale:** The user needs to know what will happen when they un-complete. Showing the destination segment sets clear expectations.

### Decision 5: Swipe-to-un-complete calls existing toggleCompletion

**Chosen:** The un-complete action calls the existing `toggleCompletion` logic in the `modelContext` — same code path that `ReminderSegmentDetailView` uses.

**Rationale:** `toggleCompletion` already handles setting `isCompleted = false`, clearing `completionDate`, and the task naturally reappears in its correct segment based on `dueDate`. No new data logic needed.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Tasks completed before the `completionDate` field was introduced may have `nil` completionDate | These will never appear in the 30-day window. Acceptable — they're old and unlikely to need un-completing. If needed, they fall back to `createdAt` or are excluded. |
| Accidentally un-completing a task that was intentionally completed | The swipe action can have a confirmation or be a full-swipe-only gesture. The current pattern in the app uses immediate action. Follow existing patterns. |
| 30-day window might miss edge cases | The constant can be easily adjusted. Make it a private `static let` at the top of the view. |
