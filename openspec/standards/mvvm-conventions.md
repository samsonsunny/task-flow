# MVVM Conventions for TaskFlow

## Directory Structure

All ViewModels live alongside their feature in a `ViewModels/` subdirectory:

```
TaskFlow/Features/Reminders/
├── ViewModels/
│   ├── ListDetailViewModel.swift
│   ├── ReminderSegmentViewModel.swift
│   ├── ReminderEditorViewModel.swift
│   ├── ListsTabViewModel.swift
│   └── CompletedViewModel.swift
├── ListDetailView.swift
├── ReminderSegmentDetailView.swift
├── ...
```

## Pattern

### ViewModel

```swift
import SwiftUI
import SwiftData

@Observable
final class FeatureViewModel {
    private let modelContext: ModelContext

    // --- Published state ---
    private(set) var derivedData: [SomeType] = []

    // --- Init ---
    init(modelContext: ModelContext /*, feature-specific params */) {
        self.modelContext = modelContext
    }

    // --- Update entry point (called by view) ---
    func update(/* data from @Query */ now: Date = Date()) {
        // Recompute all derived state
    }

    // --- Mutations ---
    func someMutation() { ... }
}
```

### View

- View holds `@Query` for SwiftData fetching
- View creates and owns the ViewModel as `@State`
- View passes `modelContext` from `@Environment(\.modelContext)` to VM init
- View calls `viewModel.update(...)` on appear and when query results change
- View delegates all user actions to VM methods
- View never calls `modelContext` directly or mutates models

```swift
struct FeatureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \.createdAt) private var items: [Item]

    @State private var viewModel = FeatureViewModel(modelContext: modelContext)

    var body: some View {
        List(viewModel.derivedData) { item in
            ...
        }
        .onAppear { viewModel.update(items: items) }
        .onChange(of: items) { _, new in viewModel.update(items: new) }
    }
}
```

## Key Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Observation | `@Observable` macro | Matches existing `AppState`, simpler than `ObservableObject` |
| Data access | View holds `@Query` | `@Query` requires View context; VM receives data via `update()` |
| Model context | Passed at init | VM needs it for all mutations |
| State entry point | Single `update()` method | Simple, predictable, easy to debug |
| UI-only state | Stays in view | `@FocusState`, `@State` for sheet booleans, `editMode` |
| Derived state | Computed in VM | Testable, single source of truth |

## Testing

ViewModels are unit-testable by constructing them with a in-memory `ModelContainer`:

```swift
@Test func testSomeMutation() {
    let container = TaskPreviewData.container()
    let vm = FeatureViewModel(modelContext: container.mainContext)
    vm.update(...)
    vm.someMutation()
    #expect(vm.derivedData.count == 1)
}
```

## What Stays in the View

- `@Query` — SwiftData auto-refresh requires View context
- `@FocusState` — keyboard focus is a view concern
- `@Environment(\.dismiss)`, `@Environment(\.editMode)` — navigation concerns
- Sheet/dialog *presentation* (the `.sheet()` / `.alert()` modifiers) — driven by VM state booleans
- Animation wrappers — `withAnimation {}` around VM calls
- `Timer.publish` + `.onReceive` — timer is a SwiftUI concern; VM exposes `refreshNow()`
