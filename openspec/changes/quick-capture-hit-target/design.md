## Context

The quick capture chevron button exists in two places:

1. `TimelineView.swift:188-197` — used in Today/Tomorrow/Upcoming tabs
2. `DetailView.swift:255-264` — used in list detail

Both have an identical `openQuickCaptureEditor()` method:

```swift
private func openQuickCaptureEditor() {
    let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
    let (initialDate, initialTitle) = viewModel?.openQuickCaptureEditor(text: text, captureDate: activeCaptureDate) ?? (nil, "")
    newReminderConfig = NewReminderConfig(
        initialDate: initialDate,
        initialListID: nil,
        initialTitle: initialTitle
    )
    quickCaptureText = ""
    activeCaptureDate = nil
}
```

### The bug

When the user taps the chevron, two things happen in a single SwiftUI transaction:

1. The button action fires `openQuickCaptureEditor()` which sets `newReminderConfig` (triggers sheet) AND `activeCaptureDate = nil` (removes the TextField from hierarchy) in the same state update
2. The List's `.simultaneousGesture(TapGesture)` fires `isQuickCaptureFocused = false`

The `activeCaptureDate = nil` removes the quickCaptureRow, which removes the TextField, which triggers keyboard dismissal. UIKit begins the keyboard dismissal animation. When SwiftUI then tries to present the sheet (from `newReminderConfig`), **UIKit silently drops the presentation** because it is in the middle of a transition (the keyboard dismissal animation).

`commitQuickCapture()` works because it sets `skipNextDismiss = true` and re-focuses the field (`isQuickCaptureFocused = true`), keeping the keyboard up. `openQuickCaptureEditor()` does neither.

### Fix

Decouple the sheet presentation from the view hierarchy change by scheduling it on the next runloop tick, after the keyboard dismissal animation has begun:

1. Set `skipNextDismiss = true` — prevents the `onChange(of: isQuickCaptureFocused)` async block from running (it would redundantly clear already-cleared values)
2. Clear `quickCaptureText` and `activeCaptureDate` synchronously — removes the quickCaptureRow
3. Set `newReminderConfig` in a `Task { @MainActor in }` block — delays sheet presentation until the next runloop tick, after UIKit has started processing the keyboard dismissal

## Goals / Non-Goals

**Goals:**
- Chevron tap opens the editor sheet reliably, even when the keyboard is visible
- Keep the existing UX: sheet pre-fills the title and date from context

**Non-Goals:**
- No changes to `commitQuickCapture`, chevron visual appearance, hit target, or gesture handling
- No changes to swipe actions, list gestures, or keyboard behavior
- No spec-level behavior changes

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Sheet scheduling | `Task { @MainActor in }` (next runloop tick) | Avoids UIKit transition conflict. `DispatchQueue.main.async` would also work but `Task` is the Swift-idiomatic async dispatch. |
| `skipNextDismiss` | Set to `true` | Prevents the `onChange` handler from adding redundant `withAnimation` blocks that might interfere with view updates. |

## Risks / Trade-offs

- **[None] Timing reliability**: `Task { @MainActor in }` runs on the very next main actor tick — milliseconds after the synchronous code. The keyboard animation starts synchronously when `resignFirstResponder` is called, so by the time the `Task` runs, the keyboard dismissal is already queued and no longer blocks new presentations.
- **[None] User-perceived delay**: The delay is ~1 frame (16ms at 60fps). Imperceptible.
