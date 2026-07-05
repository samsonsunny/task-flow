## Why

The quick capture row appears at the bottom of the List when the user taps the FAB. The existing `quickCaptureScroll` modifier scrolls to the row on row-appear, but the scroll happens *before* the keyboard animates up. By the time the keyboard settles, the row is hidden behind it.

The user must manually scroll to see the field — defeating the purpose of auto-scroll.

## What Changes

- Extend the shared `quickCaptureScroll` view modifier (in `QuickCaptureRow.swift`) to also scroll to the quick capture field *after* the keyboard finishes animating (`keyboardDidShowNotification`)
- No call-site changes needed — both `ListDetailView` and `TimelineView` already use the modifier

## Behavioral Matrix

| Trigger | Before | After |
|---------|--------|-------|
| Tap FAB | Row appears, scrolls to bottom, keyboard covers it | Row appears and scrolls (same), then re-scrolls after keyboard settles → row visible above keyboard |
| Keyboard appears | No keyboard-aware adjustment | Keyboard `didShow` triggers second scroll to correct position |
| Subsequent keyboard shows (tap back into field) | Row visible but keyboard may cover it | Row re-scrolls into visible area above keyboard |

## Impact

- `TaskFlow/Views/Components/QuickCaptureRow.swift` — enhanced modifier
- No ViewModel, model, or other file changes
