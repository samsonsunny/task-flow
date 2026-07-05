## Why

`QuickCaptureRow` currently exposes `@FocusState.Binding var isFocused` and requires each parent view to manage `skipNextDismiss`, `@FocusState`, a 12-line `onChange(of: isQuickCaptureFocused)` handler, and a `commitQuickCapture()` method. This exact same boilerplate is duplicated in both `ListDetailView` and `ReminderSegmentDetailView` (~30 lines per view). The `skipNextDismiss` dance exists only because focus is managed externally — if the component owns its own focus, the guard is unnecessary.

## What Changes

- **QuickCaptureRow owns `@FocusState` internally** — removes `@FocusState.Binding` parameter, handles focus-loss commit and dismiss inside the component
- **Replace `onSubmit: () -> Void` with `onSubmit: (String) -> Void`** — passes the committed text directly instead of requiring parent to read from a binding
- **Add `onDismiss: () -> Void` callback** — parent provides a cleanup closure (e.g., `isQuickCapturing = false` or `activeCaptureDate = nil`)
- **Remove `dateHint`** — unused visual clutter
- **Remove `import Combine`** from QuickCaptureRow.swift — no longer needed
- **Delete `skipNextDismiss`** from both views — no longer needed
- **Delete `commitQuickCapture()` methods** from both views — replaced by inline `onSubmit` closures
- **Delete `onChange(of: isQuickCaptureFocused)` handlers** from both views — handled internally by component
- **Delete `@FocusState var isQuickCaptureFocused`** from both views — moved into component

## Capabilities

### New Capabilities
*(none — no new capabilities introduced, only refactoring of existing ones)*

### Modified Capabilities
- `list-inline-capture`: QuickCaptureRow interface changes — `@FocusState.Binding` and `dateHint` removed, `onDismiss` added, `onSubmit` now passes `String`
- `task-row-display`: Same interface change for Today/Tomorrow/Upcoming capture rows

## Impact

- `TaskFlow/Views/Components/QuickCaptureRow.swift` — rewrite component body
- `TaskFlow/Features/Lists/DetailView.swift` — remove ~30 lines of boilerplate
- `TaskFlow/Features/Tasks/Timeline/TimelineView.swift` — remove ~35 lines of boilerplate (including `commitQuickCaptureWithDate`)
