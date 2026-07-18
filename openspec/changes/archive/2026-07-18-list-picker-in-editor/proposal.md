## Why

The task editor (ReminderEditorView) does not show which list a task belongs to, nor does it allow changing the list. Users have no visibility into or control over list assignment from the editor — the most natural place to manage task metadata. This is needed for both new task creation and editing existing tasks.

## What Changes

- Add a "List" row to the editor form that displays the current list name
- Tapping the row navigates to a full-screen list picker with search
- The picker shows all lists organized by groups (reusing `buildListSections`)
- The current list is pre-selected with a checkmark
- On selection, the draft's `listName` is updated
- No schema migration or model changes required — `ReminderDraft.listName` and `ReminderDraftMapper` already support this

## Capabilities

### New Capabilities
- `list-picker`: Full-screen searchable list picker for assigning tasks to lists

### Modified Capabilities
- `reminder-authoring`: Editor now exposes list assignment UI (list row + navigation to picker)

## Impact

- `Features/Editor/EditorView.swift` — new List section row with navigation
- `Features/Editor/EditorViewModel.swift` — expose list name from draft, handle selection
- `Features/Editor/Draft.swift` — no changes needed (listName already exists)
- New file: `Features/Editor/ListPickerView.swift` — full-screen picker view
- No changes to data model, SwiftData schema, or other features
