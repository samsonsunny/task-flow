## Context

The app currently has no badge management. `NotificationService` schedules notifications without setting `content.badge`, and no code reads task state to compute a badge number.

Key existing infrastructure:
- `ReminderSegmentLogic.filteredTasks(tasks:for:now:)` — already filters by segment, reusable for badge computation
- `ReminderSegmentViewModel` already stores `allTasks` and recomputes `overdueTasks` on every `update()` call
- `ReminderSegmentDetailView` has a 60s `refreshTimer` that calls `viewModel?.refreshNow()`
- `TaskFlowApp` has `.onAppear` + `reschedulePendingOnLaunch`

## Goals / Non-Goals

**Goals:**
- Badge shows overdue + today task count on the app icon
- Badge persists across app restarts (survives termination)
- Badge updates reactively on: task completion, creation, deletion, reschedule, and foreground
- Badge does NOT clear on app open

**Non-Goals:**
- No per-list badge counts
- No separate overdue vs today badge (single combined number)

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Computation | `ReminderSegmentLogic.badgeCount(tasks:now:)` | Reuses existing filtering logic. Static method — no instance needed. Single source of truth. |
| Trigger points | Mutation paths in ViewModels + foreground | Every path that changes task state (complete, create, delete, reschedule) calls `UIApplication.shared.applicationIconBadgeNumber = newCount`. Foreground ensures correctness after termination. |
| Notification badge | `content.badge = badgeCount` at schedule time | The badge value at notification time may be stale, but it's better than no badge. The badge corrects itself when the app opens. |
| Authorization | Add `.badge` to existing `requestAuthorization` options | Required to set badge number. On iOS 17+, re-prompting for additional options is handled gracefully by the system (doesn't show a second prompt to the user if already authorized). |
| Persistence | `UserDefaults` for last known count | Survives app termination. On launch, read saved count, then foreground refresh corrects it. |

## Data Flow

```
Mutation (complete/create/delete/reschedule)
    │
    ▼
ViewModel method
    │
    ├── mutate model
    ├── save + update()         ← already exists from fix-completion-reactivity
    └── BadgeService.update()   ← new: recompute badge, set on app icon


Foreground (scenePhase.active)
    │
    ▼
TaskFlowApp
    ├── fetch all uncompleted tasks via modelContext
    └── BadgeService.update()
```

## Risks / Trade-offs

- [Multiple ViewModels could set the badge simultaneously] → Writes to `applicationIconBadgeNumber` are idempotent and cheap. Last writer wins, which is the correct value since all are computed from the same data.
- [Notification carries a potentially stale badge value] → True, but the badge corrects itself on next foreground. For most users, the notification-to-open cycle is fast enough that staleness is negligible.
- [Timer tick could be missed if all timeline views are deallocated] → The 60s `refreshTimer` is owned by `ReminderSegmentDetailView`. If no timeline view is visible (e.g., user is on Lists tab), the badge won't update until foreground. Acceptable — foreground always corrects it.
