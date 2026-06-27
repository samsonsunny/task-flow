## Context

`ReminderEditorView` (424 lines) is the task creation/editing form presented as a sheet. It uses `ReminderDraft` (a value type) for form state and `ReminderDraftMapper.apply()` for the save pipeline. The view manages: initialization (draft from task vs. from defaults), draft validation, dirty tracking, save with notification scheduling, subtask CRUD, and discard confirmation. All mutation logic is in private view methods.

`ReminderDraft` and `ReminderDraftMapper` are already unit tested — the VM adds test coverage for the orchestration layer (save pipeline, dirty tracking, subtask validation).

## Goals / Non-Goals

**Goals:**
- Extract `ReminderEditorViewModel` as an `@Observable` class owning all editor state and business logic
- VM owns: `ReminderDraft`, `isDirty` tracking, `isDiscardConfirmationPresented`, save/validate, subtask CRUD, notification scheduling
- View retains: `@Query` for lists/tags, `expandedPicker`/`pressedRow` UI state, `isTitleFocused`, body rendering
- All save and subtask operations become VM methods, testable without view lifecycle

**Non-Goals:**
- Changing `ReminderDraft` or `ReminderDraftMapper` interfaces
- Altering form layout, picker behavior, or animations
- Changing how the editor is presented or dismissed
- Adding new fields or features to the editor

## Decisions

### 1. VM receives modelContext, lists, and tags at initialization

```swift
@Observable
final class ReminderEditorViewModel {
    private let modelContext: ModelContext
    private let reminderLists: [ReminderList]
    private let reminderTags: [ReminderTag]

    @MainActor
    init(modelContext: ModelContext, task: TaskItem? = nil, initialDate: Date? = nil,
         initialListID: ReminderList.ID? = nil, initialTitle: String = "",
         reminderLists: [ReminderList], reminderTags: [ReminderTag]) { ... }
}
```

**Rationale:** The view holds `@Query` for lists/tags and passes them to the VM. The VM needs `modelContext` for insert/delete/save.

### 2. Draft as @Observable state, not init-only

The `draft` property is mutable `@Observable` state in the VM, initialized in init and updated via form bindings. No `State` wrapping needed in the view.

### 3. Dirty tracking stays in VM

```swift
var isDirty: Bool { draft != initialDraft }
```

The VM holds both `draft` and `initialDraft` and exposes `isDirty` as a computed property, matching the current pattern.

### 4. Save pipeline is a single VM method

```swift
func save() -> TaskItem?
```

Returns the saved task (or nil if invalid). Handles: validation, `ReminderDraftMapper.apply()`, model insertion for new tasks, sort order assignment, and notification scheduling. The view calls this and dismisses on success.

### 5. Subtask operations in VM

```swift
func addSubtask(title: String, to parent: TaskItem) -> Bool
func deleteSubtask(_ subtask: TaskItem)
func toggleSubtaskCompletion(_ subtask: TaskItem)
```

Current view-only logic moves to VM. View just passes user input and renders results.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Initialization complexity**: 4 optional init parameters with different draft-building logic | Keep init complexity in VM. Existing logic from view's `init` is copied as-is, then simplified later. |
| **Discard confirmation**: VM needs to track whether to show the alert | `showDiscardConfirmation` is a VM boolean. View renders `.alert` based on it. |
| **Save triggers dismiss**: View needs to know when to call `dismiss()` | `save()` returns the saved task. View dismisses only on non-nil return. |
