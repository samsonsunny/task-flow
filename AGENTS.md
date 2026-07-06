# TaskFlow — AI Agent Instructions

## Architecture: MVVM

This project follows the **MVVM (Model-View-ViewModel)** pattern. All view-layer code must follow these rules:

### Rules

1. **Views never contain business logic or data mutations.** Views observe ViewModel state and delegate all actions to the ViewModel.
2. **All ViewModels are `@Observable` classes.** Do NOT use `ObservableObject` / `@Published`.
3. **Views hold `@Query` for SwiftData fetching.** ViewModels receive data via an `update()` method — they do not own `@Query`.
4. **ViewModels receive `modelContext` at init** from the view's `@Environment(\.modelContext)`.
5. **ViewModels are co-located with their View** in the same folder.
6. **UI-only state** (`@FocusState`, `@State` for sheet booleans, `@Environment(\.dismiss)`) stays in the view.
7. **Every mutation must call `update()` after `modelContext.save()`.** `onChange(of:)` uses `Equatable` comparison; `@Model` objects compare equal by `persistentModelID`, so property-only changes are invisible to `onChange`. Explicit `update()` is the only reliable way to recompute derived state after a mutation. For inserts/deletes, update `allTasks` (add/remove) before calling `update()`.

### Date formatting

When using `DateFormatter.setLocalizedDateFormatFromTemplate()`, always set `formatter.locale` **before** calling the template method. The template parsing is locale-sensitive — it uses whatever locale is set at call time to determine component order (e.g., "May 15" vs "15 May"). Setting locale afterward only affects component names, not their order.

### File organization

Features are split into domain-based folders under `Features/`. Each screen co-locates its View and ViewModel in the same folder. Truly shared files stay at the feature root or in `Views/Components/`.

```
TaskFlow/Features/
├── Tasks/                           (Today/Tomorrow/Upcoming tabs)
│   ├── TodayView.swift
│   ├── TomorrowView.swift
│   ├── UpcomingView.swift
│   ├── TimelineView.swift
│   ├── TimelineViewModel.swift
│   ├── TimelineSections.swift
│   └── TimeSegments.swift
├── Lists/                           (Later tab + list detail)
│   ├── ListView.swift
│   ├── ListViewModel.swift
│   ├── DetailView.swift
│   └── DetailViewModel.swift
├── Editor/                          (create/edit reminder, schedule picker)
│   ├── EditorView.swift
│   ├── EditorViewModel.swift
│   ├── Draft.swift
│   ├── DatePickerSheet.swift
│   └── DatePickerViewModel.swift
├── Completed/
│   ├── CompletedView.swift
│   └── CompletedViewModel.swift
├── Settings/
│   └── SettingsView.swift
├── FloatingAddButton.swift
└── MainTabView.swift
```

### Full conventions

See `openspec/standards/mvvm-conventions.md` for the detailed pattern reference, including the ViewModel template, testing approach, and what stays in the view.

### Product mental model

Read `openspec/specs/app-mental-model/spec.md` before making architectural or navigation decisions. It defines the two-axis model (attention vs home) that all features build on.

### Existing specs

Feature specs are in `openspec/specs/`. Active changes with implementation tasks are in `openspec/changes/`.
