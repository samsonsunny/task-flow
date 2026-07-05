## Why

Quick capture is designed for rapid task chaining — user types a task, presses Return, and immediately types the next. Currently, pressing Return causes a keyboard flicker (dismiss → re-appear) that breaks flow. Pressing Return on an empty field is a no-op, requiring an extra tap-away to dismiss. Both violate the "zero friction" goal of quick capture.

## What Changes

- Add `.submitBehavior(.stay)` to the QuickCaptureRow TextField so iOS never dismisses the keyboard on submit
- Split `handleSubmit()` into two branches: non-empty text commits and stays focused for chaining; empty text explicitly resigns focus and dismisses the row
- Remove the iOS-initiated keyboard dismiss animation entirely — the keyboard stays visible between chained entries
- Update the "Empty commit" spec requirement: pressing Return on an empty field now dismisses it (was: no-op)

## Capabilities

### New Capabilities
*(none)*

### Modified Capabilities
- `list-inline-capture`: Change the "Empty commit" scenario — pressing Return on an empty field SHALL dismiss the row (was: no-op). Add "keyboard stays visible" to the commit scenario.
- `upcoming-inline-capture`: Add "keyboard stays visible" to the commit scenario.

## Impact

- `TaskFlow/Views/Components/QuickCaptureRow.swift` — one-line `.submitBehavior(.stay)` addition and `handleSubmit()` branch rewrite
- `openspec/specs/list-inline-capture/spec.md` — update one scenario
- `openspec/specs/upcoming-inline-capture/spec.md` — minor clarification
