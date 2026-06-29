## Why

Tapping the chevron button on the quick capture row (which should open the full ReminderEditorView sheet) dismisses the keyboard instead. The editor never appears. This makes the "open full editor" action from quick capture completely broken, forcing users to retype their task if they need notes, list assignment, or subtasks.

## What Changes

- Fix `openQuickCaptureEditor()` in `TimelineView.swift` and `DetailView.swift` to properly present the editor sheet
- No behavioral changes — the sheet still opens with the same pre-filled context (title, date)
- No hit-target or visual changes to the chevron button itself

## Capabilities

### New Capabilities
*(none)*

### Modified Capabilities
*(none — no spec-level behavior changes)*

## Impact

- `TaskFlow/Features/Tasks/Timeline/TimelineView.swift`: ~2 lines changed in `openQuickCaptureEditor()`
- `TaskFlow/Features/Lists/DetailView.swift`: same change in the structurally identical `openQuickCaptureEditor()`
- No model, ViewModel, data flow, or view hierarchy changes
