## Context

TaskFlow’s Today and Tomorrow tabs currently only expose a trailing swipe delete action on task rows. Users often need to defer a single task by one day — a common triage action that now requires opening a context menu or schedule picker.

The app follows MVVM: views hold `@Query` and delegate all mutations to `@Observable` ViewModels. Swipe actions are configured in `TimelineView.taskListRow`, with the row UI handled by `TaskRowView`.

## Goals / Non-Goals

**Goals:**
- Allow users to reschedule a task to the next day via a single right swipe in Today and Tomorrow views.
- Include overdue tasks in Today in this behaviour.
- Keep the interaction fast: full swipe with no confirmation, light haptic on success.
- Preserve existing context menu reschedule options (Today, Tomorrow, Next Week, Later, Schedule).

**Non-Goals:**
- Adding swipe reschedule to Upcoming or Later views.
- Supporting undo toast (not requested).
- Changing the SwiftData model or rescheduling logic beyond a new ViewModel method.

## Decisions

### 1. Replace trailing delete with trailing reschedule in Today/Tomorrow

**Decision:** Remove the destructive trailing swipe from `taskListRow` when the segment is `.today` or `.tomorrow`. Add a non-destructive trailing swipe action that reschedules to the next day.

**Rationale:** SwiftUI List rows support one swipe edge at a time. Keeping only the reschedule swipe avoids conflicting gestures and matches the user’s request for right-swipe behaviour. Delete remains accessible via context menu.

**Alternative considered:** Keep both delete and reschedule as multiple trailing swipe buttons. Rejected because two trailing swipe buttons on the same row would require partial swipes, degrading the one-swipe speed the user wants.

### 2. Add `rescheduleToNextDay` to `ReminderSegmentViewModel`

**Decision:** Add a new mutation that sets the task’s due date to the next calendar day relative to today’s start.

**Rationale:** Both Today and Tomorrow share the same "push forward one day" logic. Using `Calendar.startOfDay(for: now) + 1 day` produces the correct target date for both contexts. The function will also cancel existing notifications and call `update()` to refresh the UI.

### 3. Light haptic on reschedule

**Decision:** Trigger `UIImpactFeedbackGenerator(style: .light)` on swipe completion.

**Rationale:** Provides immediate tactile confirmation that the action succeeded, without interrupting the user’s flow.

## Risks / Trade-offs

- **Users who relied on swipe-to-delete in Today/Tomorrow** → Mitigated by delete remaining in the context menu and bulk selection toolbar.
- **Swiping a parent task does not move its subtasks** → This matches existing context menu behaviour (reschedule only affects the swiped task). Subtasks with their own due dates retain their dates. Future enhancement could offer "Move task and subtasks" if requested.
- **Scheduling a time-specific task to next day loses the time component** → The `rescheduleToNextDay` method will preserve the existing `hasTime` state but set the due date to start-of-day. This is consistent with `rescheduleToToday` and `rescheduleToTomorrow`. If the user wants to preserve the time, the Schedule picker remains available.
