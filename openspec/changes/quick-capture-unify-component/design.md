## Context

`QuickCaptureRow` was extracted in a previous change to provide a shared visual component for inline quick capture across all views (ListDetailView, Today/Tomorrow, Upcoming). However, the state management boilerplate was left in the parent views:

- Each view manages its own `@FocusState`, `skipNextDismiss` guard, a 12-line `onChange(of: isQuickCaptureFocused)` dismiss handler, and a `commitQuickCapture()` method.
- The `skipNextDismiss` pattern exists purely because focus is managed externally — the component re-focuses after commit, which triggers a spurious focus-loss event that must be guarded against.
- `dateHint` is unused in practice and adds visual noise.

The `quickCaptureScroll` modifier was recently improved (with `keyboardDidShowNotification` handling) and lives as a shared extension.

## Goals / Non-Goals

**Goals:**
- Move `@FocusState` into QuickCaptureRow so it owns focus lifecycle
- Eliminate `skipNextDismiss` from both views
- Eliminate `onChange(of: isQuickCaptureFocused)` handlers from both views
- Eliminate `commitQuickCapture()` methods from both views
- Remove `dateHint` parameter and `import Combine`
- Remove `@FocusState var isQuickCaptureFocused` from both views

**Non-Goals:**
- Changing `quickCaptureScroll(isActive:proxy:fieldID:)` — stays as-is
- Changing the overall field position (last row) or scroll behavior
- Changing `ListDetailViewModel` or `ReminderSegmentViewModel` commit methods

## Decisions

### Decision 1: QuickCaptureRow owns focus internally

**Interface after change:**

```
QuickCaptureRow(
    text: $quickCaptureText,
    onSubmit: { viewModel?.commitQuickCapture(text: $0, ...) },  // (String) -> Void
    onDismiss: { isQuickCapturing = false }                        // () -> Void
)
```

The component:
- Creates `@FocusState private var isFocused` internally
- On `.onSubmit`: clears text, re-focuses, calls `onSubmit(text)`
- On `onChange(of: isFocused)`: when focus lost, commits if text non-empty, calls `onDismiss()`
- No `skipNextDismiss` needed — the internal handler has complete control over the lifecycle

**Alternatives considered:**
- **ViewModifier**: Can't hold `@FocusState` — must be in a View
- **Wrapper struct**: Over-engineered for what's essentially a single component change

### Decision 2: `onSubmit` passes `String` instead of requiring parent to read binding

Before: `onSubmit: () -> Void` — parent reads `quickCaptureText` binding
After: `onSubmit: (String) -> Void` — component passes the committed text

Simpler. Fewer indirections. The parent doesn't need the binding to commit.

### Decision 3: `dateHint` removed

Never used meaningfully. The Today/Tomorrow hint is redundant with the section header.

## Risks / Trade-offs

- **[Focus lifecycle regression]** The internal `@FocusState` might not synchronize correctly with external triggers (e.g., task tap dismisses focus, or header tap sets focus). → Mitigation: FAB/header tap actions set focus via the FocusState internally, which is straightforward since the focus is in the same view hierarchy.
- **[State coupling]** `text` binding is still shared (parent owns it). If the parent clears text while the component is managing re-focus, there's no conflict — the component clears text before calling `onSubmit`, and the parent provides the fresh binding. No risk.
- **[Transition animation]** The `.transition(.move(edge: .bottom))` is on the row; focus changes don't affect layout animation. No risk.
