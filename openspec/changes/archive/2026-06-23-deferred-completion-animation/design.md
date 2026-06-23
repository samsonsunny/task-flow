## Context

Currently `toggleCompletion` sets `isCompleted = true` inside a `withAnimation` block. The task row has existing styling for `isCompletedVisualState` (strikethrough + dim at 0.82 opacity, animated at 0.18s), but the row is removed from `filteredTasks` as soon as the model updates, so the styling is barely visible before the row snaps out.

The change only affects the circle-tap completion path in `ReminderSegmentDetailView` and `ListDetailView`. No swipe-to-complete exists.

## Goals / Non-Goals

**Goals:**
- Task stays visible with completed styling for 0.6s after tap
- Row exits with fade + scale transition after the delay
- Model state (`isCompleted`, `completionDate`) set immediately on tap (durable)
- Notification cancellation happens on tap (not after delay)
- Same behavior in both `ReminderSegmentDetailView` and `ListDetailView`

**Non-Goals:**
- No swipe-to-complete path
- No undo snackbar
- No change to haptic timing (already fires before animation)
- No change to existing strikethrough/dim styling

## Decisions

**1. Display-layer delay with `@State justCompleted: Set<String>`**

The task's `taskId` is added to a local `@State` set on tap. The displayed task list includes tasks whose ID is in this set even though `isCompleted` is already `true`. After 0.6s, the ID is removed from the set, triggering the exit transition.

```
Tap → Set state: isCompleted=true, add ID to justCompleted
      → Row visible with strikethrough (existing styling)
      
0.6s later → Remove ID from justCompleted
           → Row exits via fade+scale transition
           → Row gone from list
```

**2. Fade + scale exit transition**

`.transition(.scale.combined(with: .opacity))` applied to each task row. When the row exits (ID removed from `justCompleted`), it scales down and fades out simultaneously.

**3. Notification and data state set immediately**

`NotificationService.shared.cancel(taskId:)` and `completionDate` are set on tap, not after the delay. The notification should not fire even if the user navigates away during the 0.6s window.

**4. SwiftUI `withAnimation` for exit**

The removal from `justCompleted` is wrapped in `withAnimation` to ensure the transition is animated.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| User navigates away during 0.6s window — task is already completed (good) but "just completed" set is lost | Model state is already persisted, so no data loss. The set being ephemeral is fine — the exit animation simply doesn't play. |
| Rapidly completing multiple tasks — multiple async timers | Each task has its own delay via `DispatchQueue.main.asyncAfter`. No shared timer state. |
| Task doesn't have a `taskId` | Fallback to `persistentModelID.uuidString` as the set key. |
