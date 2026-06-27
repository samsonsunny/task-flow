## Why

`ReminderEditorView` (424 lines) manages form state via `ReminderDraft`, save-with-validation, subtask CRUD, notification scheduling, and dirty-discard logic — all inside the view. The editor's initialization logic (building a draft from a task vs. from defaults) and save pipeline are untestable without launching the full sheet. Extracting a ViewModel makes the entire save/discard flow testable.

## What Changes

- Create `ReminderEditorViewModel` as an `@Observable` class owning all editor state and business logic
- `ReminderEditorView` becomes a thin consumer: observes VM state, delegates all actions to the VM
- Move to VM: `ReminderDraft` state, save/validate, `isDirty` tracking, discard confirmation, subtask CRUD, notification scheduling, and `isDiscardConfirmationPresented`
- View retains only: `@Query` for lists/tags, pure-UI state (`expandedPicker`, `pressedRow`, `isTitleFocused`), and rendering

## Capabilities

### New Capabilities
- `reminder-editor-view-model`: ViewModel for `ReminderEditorView` owning draft management, save/validate pipeline, dirty tracking, subtask CRUD, and notification scheduling

### Modified Capabilities
*None — existing specs are implementation details unaffected by MVVM extraction.*

## Impact

- **New file**: `TaskFlow/Features/Reminders/ViewModels/ReminderEditorViewModel.swift`
- **Modified**: `ReminderEditorView.swift` — reduced from ~424 lines to ~200 lines of pure view code
- **All existing specs** remain unchanged — pure refactor with no behavioral changes
