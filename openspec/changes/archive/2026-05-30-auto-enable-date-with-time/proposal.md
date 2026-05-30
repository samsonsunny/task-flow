## Why

Currently the time toggle in the Reminder Editor is disabled when the date toggle is off (`draft.dueDate == nil`). Users cannot set a time on a reminder without first explicitly enabling the date. This is an unnecessary restriction — enabling a time should implicitly set a date. The time picker row should be independently tappable and auto-enable the date when toggled on.

## What Changes

- Remove the `.disabled(draft.dueDate == nil)` constraint on the time Toggle
- When the time toggle is turned on without a date set, auto-enable the date by setting `draft.dueDate` to a default value (today)
- The time row press gesture (`DragGesture`) should also auto-enable the date when activated without a date set
- The time picker row remains gated on `draft.hasTime` for expand/collapse, but no longer depends on `draft.dueDate` being non-nil

## Capabilities

### New Capabilities
- `auto-date-on-time-enable`: When the user enables time on a reminder, the date SHALL be automatically set if not already present. The time toggle SHALL NOT be disabled when the date is unset.

### Modified Capabilities
<!-- no existing spec-level behavior is changing -->

## Impact

- `ReminderEditorView.swift` — modify the time row toggle binding and gesture handling
- `ReminderDraft` — no changes needed (already supports `dueDate` and `hasTime` independently)
