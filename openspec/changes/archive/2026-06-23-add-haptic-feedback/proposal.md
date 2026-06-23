## Why

Task completion currently has no tactile feedback. Tapping the circle to complete a task feels dead — there's no sensory confirmation that the action registered. A haptic tap makes the interaction feel responsive and satisfying.

## What Changes

- Add `UIImpactFeedbackGenerator(style: .medium)` haptic before the completion animation plays
- Fire haptic immediately on tap, before the visual animation begins
- Only on complete (not on un-complete in CompletedView)
- Per-call generator creation (no shared state)

## Capabilities

### New Capabilities
- `completion-haptic-feedback`: Haptic feedback on task completion action

### Modified Capabilities

None — completion behavior is unchanged specification-wise.

## Impact

- **Modified files**: `ReminderSegmentDetailView.swift` and `ListDetailView.swift` — add haptic trigger in `toggleCompletion`
- **Dependencies**: `UIKit` (already imported transitively via SwiftUI)
