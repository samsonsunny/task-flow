## Why

The notes field in the reminder editor (both create and edit flows) is a `TextField(axis: .vertical)` with `.lineLimit(1...4)`. Once notes exceed 4 lines, the field scrolls internally within a fixed 4-line frame. On small-screen devices this makes long notes nearly impossible to review or edit — the user is forced to scroll a tiny viewport. The same 4-line limit applies in `TaskRowView`, but that's appropriate for a summary row; the editor should give full access to content.

## What Changes

- Replace the notes `TextField(axis: .vertical)` in `EditorView` with a `TextEditor` that auto-grows with content up to a configurable max height (~200pt / ~8-10 lines).
- Add a placeholder overlay for empty notes state (TextEditor has no native placeholder).
- Remove the `.lineLimit(1...4)` constraint on the notes field.
- Apply the same change to both create and edit flows (both use the same `ReminderEditorView`).
- `TaskRowView` notes display stays at 4 lines — no change needed there.

## Capabilities

### New Capabilities

- `expandable-notes-editor`: Auto-growing notes TextEditor in the reminder create/edit flow, replacing the fixed 4-line TextField with a scrollable, height-capped TextEditor that supports placeholder text.

### Modified Capabilities

- `reminder-authoring`: The notes field input control changes from `TextField(axis: .vertical)` with `.lineLimit(1...4)` to a `TextEditor` with auto-grow and maxHeight cap. The notes field behavior (editing, binding to draft, save/discard) stays the same — only the presentation changes.

## Impact

- `TaskFlow/Features/Editor/EditorView.swift` — swap TextField for TextEditor, add placeholder overlay, add height frame
- `TaskFlow/Features/Editor/EditorViewModel.swift` — no changes expected (Draft binding stays the same)
- `TaskFlow/Features/Editor/Draft.swift` — no changes (notes is already a String)
- `TaskFlow/Views/Components/TaskRowView.swift` — no changes (stays at 4-line display)
- No new dependencies required (TextEditor is built into SwiftUI)
