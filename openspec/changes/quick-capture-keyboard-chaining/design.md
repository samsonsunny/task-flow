## Context

`QuickCaptureRow` is a shared component used across ListDetailView, Today, Tomorrow, and Upcoming views for inline task creation. It owns its `@FocusState` internally and exposes `onSubmit: (String) -> Void` and `onDismiss: () -> Void` callbacks.

The current `handleSubmit()` method:
1. Guards empty text (no-op on Return with empty field)
2. Clears text
3. Sets `isFocused = true` (to counteract iOS's default keyboard dismiss animation)
4. Calls `onSubmit(text)`

Step 3 is a workaround — iOS's `UITextField` (which SwiftUI wraps) begins a keyboard-dismiss animation when Return is pressed with `.submitLabel(.done)`. Setting `isFocused = true` in the handler cancels this animation, but the animation has already started, causing a visual flicker (keyboard slides down a few pixels then slides back up).

## Goals / Non-Goals

**Goals:**
- Keyboard stays fully visible when committing a task via Return — no flicker, no dismiss animation
- Pressing Return on an empty field dismisses the row (commits nothing)
- Eliminate the `isFocused = true` workaround in `handleSubmit()` — no longer needed when the keyboard isn't dismissed in the first place
- Eliminate the race condition between `.onSubmit` and `onChange(of: isFocused)` — with `.stay`, Return never triggers a focus change

**Non-Goals:**
- Changing the tap-away dismiss behavior — `onChange(of: isFocused)` for focus loss remains as-is
- Changing the QuickCaptureRow interface — `onSubmit` and `onDismiss` stay
- Changing other views or ViewModels

## Decisions

### Decision 1: Use `.submitBehavior(.stay)` instead of post-hoc re-focus

iOS 17+ introduced `.submitBehavior(.stay)` on `TextField`, which prevents the system from resigning first responder when the Return key is pressed. The `onSubmit` closure still fires, but the keyboard never starts a dismiss animation.

**Before (current):**
```swift
TextField("New Reminder", text: $text)
    .focused($isFocused)
    .onSubmit(handleSubmit)
    .submitLabel(.done)
```
→ iOS dismisses keyboard → `handleSubmit()` re-focuses → flicker

**After:**
```swift
TextField("New Reminder", text: $text)
    .focused($isFocused)
    .onSubmit(handleSubmit)
    .submitLabel(.done)
    .submitBehavior(.stay)
```
→ iOS keeps keyboard → `handleSubmit()` runs → no dismiss animation at all

**Alternatives considered:**
- **Post-hoc re-focus (current approach)**: Doesn't fix the flicker because the dismiss animation has already started.
- **UIViewRepresentable UITextField**: Full control via `textFieldShouldReturn: return false`, but this would replace the SwiftUI TextField with a UIKit wrapper. More code, same result. `.submitBehavior(.stay)` achieves the same effect in one line.

### Decision 2: `handleSubmit` branches on empty text

With `.submitBehavior(.stay)`, pressing Return on an empty field no longer triggers a focus change. So `onChange(of: isFocused)` won't fire either. The empty-text case must be handled explicitly in `handleSubmit`:

```swift
private func handleSubmit() {
    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !t.isEmpty else {
        isFocused = false
        onDismiss()
        return
    }
    text = ""
    onSubmit(t)
}
```

Note that `isFocused = true` is removed entirely — it's no longer needed because `.stay` keeps the keyboard visible. The re-focus for chaining happens naturally because focus is never lost.

**Alternatives considered:**
- **Guard (current approach)**: No-op on empty. Requires user to tap away to dismiss. One more gesture per interaction cycle.
- **Remove empty-text handling entirely**: The guard would trigger `onChange(of: isFocused)` via the dismiss, but this adds a dependency on the onChange handler firing (which is the pattern we're eliminating the race for).

## Risks / Trade-offs

- **[iOS version]** `.submitBehavior(.stay)` requires iOS 17+. The project already targets iOS 17+ (uses `@Observable` macro). No risk.
- **[Behavior change]** Pressing Return on an empty field now dismisses the row. Users who accidentally tap the FAB and then press Return to dismiss might be surprised — but this matches Apple Reminders behavior and is more intuitive than the current no-op.
- **[Tap-away still works]** The `onChange(of: isFocused)` path for tap-away dismissal is unchanged and unaffected by `.submitBehavior(.stay)` — tapping outside the field still triggers focus loss, which fires the onChange handler.
