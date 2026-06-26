## Context

`ListDetailView` (526 lines) manages a single task list with nested subtasks, drag-drop reorder, quick capture, completion lifecycle, and scheduling. Currently all logic lives in the view: `@Query` fetches data, computed properties filter/flatten, private methods mutate. The stateless helpers (`midpoint`, `widen`, `NotificationService`) are already extracted, but the orchestration layer is untestable without launching a full SwiftUI view.

The app uses `@Observable` for `AppState` already — this is the established pattern. No ObservableObject in the codebase.

## Goals / Non-Goals

**Goals:**
- Extract `ListDetailViewModel` as an `@Observable` class owning all business logic and presentation state
- `ListDetailView` becomes a thin rendering layer: observes VM state, delegates all mutations
- All task mutations (toggle completion, delete, reorder, quick capture, schedule, move to list) become VM methods
- Flat node building, collapse state, drag-drop target handling move to VM
- Existing UI behavior is preserved exactly — no visual or functional changes

**Non-Goals:**
- Changing SwiftData models or queries
- Altering UI layout, animations, or transitions
- Adding new features or capabilities
- Creating ViewModels for other views (separate proposals)

## Decisions

### 1. View holds `@Query`, passes data to ViewModel

The ViewModel receives task and list arrays as parameters to its update method, rather than owning `@Query` or `FetchDescriptor`.

```swift
@Observable
final class ListDetailViewModel {
    private(set) var flatNodes: [FlatTaskNode] = []
    private(set) var justCompleted: Set<String> = []
    private(set) var collapsedTasks: Set<PersistentIdentifier> = []
    // ...

    func update(with tasks: [TaskItem], allLists: [ReminderList], allTasks: [TaskItem], now: Date) {
        // Recompute flatNodes, filteredTasks, etc.
    }
}
```

**Rationale:** `@Query` only works inside SwiftUI Views. Keeping it in the view and pushing data into the VM avoids fighting the framework. The VM is still testable — tests can call `update(with:)` with synthetic data and assert on `flatNodes`.

### 2. `@Observable` over `ObservableObject`

Use the `@Observable` macro (iOS 17+) matching the existing `AppState` pattern. No `ObservableObject`, `@Published`, or `objectWillChange`.

**Rationale:** Consistency with existing codebase. Simpler syntax. No manual publishing.

### 3. ViewModel receives `modelContext` at init

```swift
@Observable
final class ListDetailViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext, listID: ReminderList.ID) { ... }
}
```

**Rationale:** All mutations (insert, delete, save) go through `modelContext`. The VM needs it. The view passes it from `@Environment(\.modelContext)`.

### 4. One update entry point, not scattered signals

The View provides a single `update(...)` call, typically triggered from `var body` or `.onChange`. The VM recomputes all derived state at once. No publisher chains or Combine pipelines.

**Rationale:** Simple, predictable, easy to debug. SwiftUI already efficiently diff's the output. No need for fine-grained reactive updates at this scale.

### 5. ViewModel owns action methods, View renders

```swift
// View calls:
viewModel.toggleCompletion(for: task)
viewModel.commitQuickCapture(text: quickCaptureText, in: currentList)
viewModel.moveTask(task, to: list)

// View reads:
ForEach(viewModel.flatNodes) { node in ... }
```

**Rationale:** Clean separation. View never mutates models or calls `modelContext` directly.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Performance**: VM recomputes flatNodes on every view update | SwiftUI's diffing is efficient. FlatNode array is trivially computable. If needed, add caching with invalidation. |
| **`update()` called too frequently** | SwiftUI coalesces updates. The compute is cheap (filter + sort a few hundred items max). |
| **Regressions in drag-drop reorder** | Drag-drop is the most complex interaction. The VM moves the sort order math, keeping the same algorithm. Test coverage on `midpoint`/`widen` already exists. |
| **View still has some state** | UI-only state (edit mode, FocusState) stays in the view — that's correct MVVM. |
