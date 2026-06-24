## Why

Tapping the complete circle instantly removes the task row — there's no chance for the user to visually register what happened. A brief hold with strikethrough styling followed by a smooth exit animation makes the interaction feel deliberate and satisfying.

## What Changes

- On tap, immediately set `isCompleted = true` (data durable)
- Keep the row visible with completed styling for 0.6s
- After 0.6s, remove the row with a fade + scale exit transition
- No swipe-to-complete path — circle tap only
- No undo snackbar

## Capabilities

### New Capabilities
- `completion-animation`: Deferred removal and exit animation on task completion

### Modified Capabilities

None.

## Impact

- **Modified files**: `ReminderSegmentDetailView.swift` and `ListDetailView.swift` — local state tracking, delayed removal
- **Potentially modified**: `TaskRowView.swift` — transition modifier if not applied at list level
