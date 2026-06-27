## Why

When the user completes a task in the timeline list (Today/Tomorrow), the task remains visible indefinitely instead of disappearing after the 0.6s exit animation delay. The view only corrects itself when switching tabs and back. This breaks the existing `completion-animation` spec requirement: "after 0.6 seconds, the row exits with a fade + scale transition."

## What Changes

- `ReminderSegmentViewModel.toggleCompletion()` will save the model context and recompute derived state after mutating a task's completion status
- The 0.6s deferred exit will actually trigger a state recomputation so the row exits properly
- No changes to the view layer or the animation spec

## Capabilities

### New Capabilities
*(none — internal fix, no new capability)*

### Modified Capabilities
*(none — existing `completion-animation` spec requirements are correct, implementation was incomplete)*

## Impact

- `TimelineViewModel.swift` (formerly `ReminderSegmentViewModel.swift`): ~3 lines added in `toggleCompletion`
- No API changes, no view changes, no model changes
