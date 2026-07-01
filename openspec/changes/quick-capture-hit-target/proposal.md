## Why

The quick capture chevron button doesn't open the editor sheet — tapping it just dismisses the keyboard and the row disappears. The root cause is that the chevron exists at all: with commit-on-defocus behavior (Apple Reminders model), the chevron is unreachable because tapping outside the field commits the task first.

Rather than fighting UIKit's presentation mechanics with hacks, the fix is to align with the standard pattern:

1. **Remove the chevron** — it's a dead control in commit-on-defocus model
2. **Switch to commit-on-defocus** — tapping outside the quick capture field commits the task (if text exists), matching Apple Reminders behavior

## What Changes

- Remove the chevron button (`chevron.right.circle`) from both `TimelineView.swift` and `DetailView.swift`
- Remove the `openQuickCaptureEditor()` method from both files
- Change the `onChange(of: isQuickCaptureFocused)` handler to commit the task on defocus (instead of just clearing)
- `commitQuickCapture()` (Enter key) stays unchanged — it re-focuses for rapid chaining

## Behavioral Matrix

| Trigger | Current | New |
|---------|---------|-----|
| Tap FAB | Row appears, keyboard auto-focuses | Same |
| Type text | Text entered | Same |
| Press Enter | Task committed, row stays, re-focused | Same |
| Tap outside | Row + text discarded (BAD) | Task committed (if text), row dismissed |
| Chevron tap | Sheet broken (keyboard dismissal race) | Removed — no longer exists |
| Swipe cancel | Row + text dismissed | Same |

## Impact

- `TaskFlow/Features/Tasks/Timeline/TimelineView.swift`
- `TaskFlow/Features/Lists/DetailView.swift`
- No model, ViewModel, data flow, or spec changes
