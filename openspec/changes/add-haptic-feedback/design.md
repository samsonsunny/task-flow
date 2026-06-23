## Context

The app has two `toggleCompletion` methods: one in `ReminderSegmentDetailView` and one in `ListDetailView`. Both are triggered by tapping the circle in `TaskRowView`. Currently they toggle `isCompleted` inside a `withAnimation` block with no haptic feedback.

No `UIFeedbackGenerator` usage exists anywhere in the app.

## Goals / Non-Goals

**Goals:**
- Play a medium-impact haptic when a task is completed (circle tap)
- Fire before the completion animation for immediate tactility
- Only on complete, not on un-complete (CompletedView)

**Non-Goals:**
- No haptic on swipe actions, list reordering, or other gestures
- No configuration or customization of haptic style
- No shared generator instance management

## Decisions

**1. Haptic type: `UIImpactFeedbackGenerator(style: .medium)`**
- Medium weight provides a satisfying "click" that confirms the action without being jarring
- Light is too subtle to feel deliberate; heavy is too aggressive for a frequent action

**2. Timing: before animation**
- Haptic fires immediately on tap, then `withAnimation` runs
- User feels the tap first, sees the visual change second — mimics real-world tactile priority

**3. Lifecycle: per-call**
- Create, prepare, trigger, release in one shot
- No `@State` or stored generator — avoids lifecycle management and stale references

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Haptic on simulator does nothing | `UIImpactFeedbackGenerator` silently no-ops on simulator — no crash, just no feedback. Expected behavior. |
| Medium impact might be too strong for some users | iOS lets users disable system haptics in Settings. App doesn't need its own toggle. |
