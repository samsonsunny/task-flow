## Context

The app has a task context menu with Today, Tomorrow, Later, and Schedule options. Each option sets `dueDate` on the `TaskItem` model. The reschedule pattern is duplicated across `ReminderSegmentViewModel` and `ListDetailViewModel`. The `TaskRowView` component accepts optional closures for each action, and calling views wire them up.

Current date math:
- `rescheduleToToday`: `dueDate = startOfDay(now)`
- `rescheduleToTomorrow`: `dueDate = startOfDay(now) + 1 day`

## Goals / Non-Goals

**Goals:**
- Add "Next Week" to context menu in all views
- Always land on the next Monday from today
- Follow existing reschedule pattern exactly (duplicate across ViewModels)
- No model changes, no new views

**Non-Goals:**
- Cleaning up ViewModel duplication
- Weekend-aware "next workday" for other days (just always Monday)
- Positive feedback toast on reschedule
- Smart buckets / new views

## Decisions

### Date calculation: Always next Monday

**Decision**: "Next Week" always resolves to the next Monday from today.

**Rationale**: The primary use case is Friday→Monday. Computing "same weekday +7" adds complexity for no user benefit — people think in weeks, not weekday arithmetic. Monday is the universal "next workday" mental model.

**Implementation**:
```swift
func nextMonday(from date: Date) -> Date {
    let calendar = Calendar.current
    let todayStart = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: todayStart)
    // weekday: 1=Sun, 2=Mon, ..., 7=Sat
    let daysUntilMonday: Int
    switch weekday {
    case 2: daysUntilMonday = 7   // Mon → next Mon
    case 3: daysUntilMonday = 6   // Tue → next Mon
    case 4: daysUntilMonday = 5   // Wed → next Mon
    case 5: daysUntilMonday = 4   // Thu → next Mon
    case 6: daysUntilMonday = 3   // Fri → next Mon
    case 7: daysUntilMonday = 2   // Sat → next Mon
    case 1: daysUntilMonday = 1   // Sun → next Mon
    default: daysUntilMonday = 7
    }
    return calendar.date(byAdding: .day, value: daysUntilMonday, to: todayStart)!
}
```

### Visibility: Hide when already due next Monday

**Decision**: `canMoveToNextWeek` returns `false` if the task's `dueDate` already falls on the next Monday.

**Rationale**: Consistent with how `canMoveToToday` and `canMoveToTomorrow` work — don't offer to move a task where it already is.

### Menu position: After Tomorrow, before Later

**Decision**: Place "Next Week" between "Tomorrow" and "Later" in the context menu.

**Rationale**: The menu orders by time horizon: Today → Tomorrow → Next Week → Later. This creates a natural escalation from shortest to longest deferral.

## Risks / Trade-offs

- **Duplication**: Two ViewModels get the same method. Accepted per user preference to maintain existing pattern.
- **Edge case — today is Monday**: "Next Week" skips 7 days (next Monday), not 0. This is correct — the user wants to defer, not keep it today.
- **No notification rescheduling**: When moving to next Monday, any existing timed notification is cancelled (same as Today/Tomorrow). If the task had `hasTime == true`, the user would need to re-schedule via "Schedule" to get a notification on the new date. This matches existing behavior for Today/Tomorrow moves.
