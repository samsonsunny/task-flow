# TaskFlow — AI Agent Instructions

## Architecture: MVVM

This project follows the **MVVM (Model-View-ViewModel)** pattern. All view-layer code must follow these rules:

### Rules

1. **Views never contain business logic or data mutations.** Views observe ViewModel state and delegate all actions to the ViewModel.
2. **All ViewModels are `@Observable` classes.** Do NOT use `ObservableObject` / `@Published`.
3. **Views hold `@Query` for SwiftData fetching.** ViewModels receive data via an `update()` method — they do not own `@Query`.
4. **ViewModels receive `modelContext` at init** from the view's `@Environment(\.modelContext)`.
5. **ViewModels are in `{Feature}/ViewModels/{Feature}ViewModel.swift`** alongside their feature.
6. **UI-only state** (`@FocusState`, `@State` for sheet booleans, `@Environment(\.dismiss)`) stays in the view.

### File organization

```
TaskFlow/Features/Reminders/
├── ViewModels/
│   ├── ListDetailViewModel.swift
│   ├── ReminderSegmentViewModel.swift
│   ├── ReminderEditorViewModel.swift
│   ├── ListsTabViewModel.swift
│   ├── CompletedViewModel.swift
│   └── TaskScheduleDatePickerViewModel.swift
├── ListDetailView.swift
├── ReminderSegmentDetailView.swift
├── ...
```

### Full conventions

See `openspec/standards/mvvm-conventions.md` for the detailed pattern reference, including the ViewModel template, testing approach, and what stays in the view.

### Existing specs

Feature specs are in `openspec/specs/`. Active changes with implementation tasks are in `openspec/changes/`.
