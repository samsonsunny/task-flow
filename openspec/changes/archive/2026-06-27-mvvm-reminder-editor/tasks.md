## 1. Create ReminderEditorViewModel

- [ ] 1.1 Create `TaskFlow/Features/Reminders/ViewModels/ReminderEditorViewModel.swift` with `@Observable` class
- [ ] 1.2 Add `modelContext`, `reminderLists`, `reminderTags` properties
- [ ] 1.3 Add `task`, `initialDraft`, `draft` with init logic matching current view
- [ ] 1.4 Add `isDirty` computed property, `isDiscardConfirmationPresented` state
- [ ] 1.5 Add `save()` method: validate, apply via `ReminderDraftMapper`, insert new task, assign sort order, schedule notification
- [ ] 1.6 Add `handleClose()`: show discard confirmation if dirty, dismiss otherwise

## 2. Move Subtask Operations to ViewModel

- [ ] 2.1 Add `addSubtask(title:to:)` creating subtask with parent/order assignment
- [ ] 2.2 Add `deleteSubtask(_:)` with model context deletion
- [ ] 2.3 Add `toggleSubtaskCompletion(_:)` with notification cancellation

## 3. Refactor ReminderEditorView to use ViewModel

- [ ] 3.1 Create VM from environment `modelContext` and `@Query` results
- [ ] 3.2 Replace `@State private var draft` with VM binding
- [ ] 3.3 Replace `isDiscardConfirmationPresented` with VM property
- [ ] 3.4 Replace `handleClose()` and `saveReminder()` with VM calls
- [ ] 3.5 Replace subtask operations with VM methods
- [ ] 3.6 Remove all `@Environment(\.modelContext)` usage and direct mutations

## 4. Verify

- [ ] 4.1 Build succeeds with no warnings
- [ ] 4.2 Creating a new task from scratch works
- [ ] 4.3 Editing an existing task works
- [ ] 4.4 Save validates empty content
- [ ] 4.5 Dirty tracking shows discard confirmation
- [ ] 4.6 Subtask add/delete/toggle works
- [ ] 4.7 Notifications scheduled on save with time
