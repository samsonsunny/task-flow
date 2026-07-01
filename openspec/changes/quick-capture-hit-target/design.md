## Context

The quick capture row appears in two places:

1. `TimelineView.swift` — Today/Tomorrow/Upcoming tabs (controlled by `activeCaptureDate`)
2. `DetailView.swift` — list detail (controlled by `isQuickCapturing`)

Both have a `quickCaptureRow` with a TextField and a chevron button, and both have an almost-identical `openQuickCaptureEditor()` method.

### The problem

The chevron exists to "upgrade" inline text to the full editor. But in practice, it's broken — tapping it dismisses the keyboard instead of opening the sheet, because UIKit drops sheet presentations during keyboard dismissal animation.

The root cause: there should be no chevron at all. The quick capture row should behave like Todoist — an inline persistent field that commits text on defocus but stays visible. A chevron makes no sense in this model.

### Changes

#### 1. Remove chevron button

Delete the chevron button from `quickCaptureRow` in both views. This includes:
- The `Button` with `chevron.right.circle` image
- The `accessibilityIdentifier("quick-capture-detail")` modifier

#### 2. Delete `openQuickCaptureEditor()`

Remove the method from both files entirely. No callers remain after the chevron is removed.

#### 3. Change `onChange(of: isQuickCaptureFocused)` handler

**Before**: On defocus, just clears the row — bad UX (text discarded).

```swift
.onChange(of: isQuickCaptureFocused) { _, focused in
    if !focused {
        DispatchQueue.main.async {
            guard !skipNextDismiss else { ... }
            withAnimation { activeCaptureDate = nil; quickCaptureText = "" }
        }
    }
}
```

**After**: On defocus, commits text (if non-empty), clears text, **row stays**.

```swift
.onChange(of: isQuickCaptureFocused) { _, focused in
    if !focused {
        DispatchQueue.main.async {
            guard !skipNextDismiss else {
                skipNextDismiss = false
                return
            }
            let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                viewModel?.commitQuickCapture(text: text, captureDate: activeCaptureDate)
            }
            quickCaptureText = ""
        }
    }
}
```

The row stays alive because `activeCaptureDate` / `isQuickCapturing` is never set to false on defocus. The only ways to dismiss the row are swipe-to-cancel or tab switch.

Note: `TimelineView` passes `captureDate:` while `DetailView` passes `listID:` — the pattern is the same, just with different ViewModel signatures.

#### 4. `commitQuickCapture()` (Enter key) — unchanged

The Enter-key path stays as-is:

```swift
private func commitQuickCapture() {
    let text = ...
    guard !text.isEmpty else { return }
    skipNextDismiss = true
    viewModel?.commitQuickCapture(...)
    quickCaptureText = ""
    isQuickCaptureFocused = true  // re-focus for chaining
}
```

Enter commits, keeps the row alive, and re-focuses for rapid chaining.

#### 5. `onChange(of: tasks)` — unchanged

The handler stays in place. With the row staying alive (never dismissed on defocus), there's no competing-transition race. The @Query update fires naturally and the ViewModel re-syncs without visual glitch.

## Flow Summary

```
FAB tap       → Row appears, keyboard focused
Type          → User types
Enter         → commit + re-focus (chaining) ✓
Tap outside   → commit (if text) + keyboard hides, row stays ✓
Tap back      → keyboard returns, text preserved ✓
Swipe cancel  → dismiss row, no commit ✓
```

## Goals / Non-Goals

**Goals:**
- Quick capture behaves like Todoist — persistent inline field, commits on defocus, stays visible
- Remove the broken, unreachable chevron control
- No change to Enter-key chaining behavior

**Non-Goals:**
- No ViewModel changes
- No spec-level behavior changes
- No model or data flow changes

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Defocus behavior | Commit + keep row alive | Todoist pattern. Row staying alive prevents hide-and-reshow glitch (no competing transitions). |
| Enter behavior | Keep unchanged | Rapid chaining is valuable for power users. |
| Chevron | Remove entirely | Dead control in commit-on-defocus model. |
| Row dismissal | Swipe-to-cancel only | Consistent swipe gesture, explicit user intent. |

## Risks

- **[Low] Accidental commits**: Tapping outside with text creates a task with no confirmation. This matches Todoist and Apple Reminders behavior. Users can edit or delete the created task.
- **[Low] Racy tap-on-task**: If the user taps a task row while the quick capture is focused, `isQuickCaptureFocused` fires first (via `.simultaneousGesture`), committing the quick capture, then the task row's `onTap` fires to open the editor. This is the same order as the current code with `skipNextDismiss` and is fine — the task is committed before the navigation.
- **[Low] Row lingers after commit**: After committing, the row stays with an empty text field. This is by design — users can tap back to add another task, or swipe-to-cancel to dismiss.
