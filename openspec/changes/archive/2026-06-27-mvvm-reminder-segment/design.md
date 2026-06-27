## Context

`ReminderSegmentDetailView` (714 lines) is the largest file in the project. It handles display across 5 segments (Today, Tomorrow, Upcoming, Later, Overdue) with filtering, sorting, date grouping, quick capture, completion lifecycle, scheduling, and rescheduling. The view uses `ReminderSegmentLogic` and `TaskUIModel` for stateless helper functions, but orchestration lives in private computed properties and methods that are untestable without view instantiation.

The app already uses `@Observable` (established via `AppState`). The same pattern applies here.

## Goals / Non-Goals

**Goals:**
- Extract `ReminderSegmentViewModel` as an `@Observable` class owning all business logic and presentation state for segment detail screens
- `ReminderSegmentDetailView` becomes a thin rendering layer: observes VM state, delegates all mutations
- All segment operations (filter, sort, group, quick capture, completion, scheduling, rescheduling, overdue toggling, timer refresh) move to VM
- `ReminderSegmentLogic` and `TaskUIModel` remain as stateless helpers — the VM calls them rather than the view
- Existing UI behavior and segment-specific rendering is preserved exactly

**Non-Goals:**
- Changing SwiftData models or queries
- Altering any UI layout, animations, or transitions
- Adding new features or capabilities
- Refactoring `ReminderSegmentLogic` or `TaskUIModel` (they stay as-is)

## Decisions

### 1. View holds `@Query`, passes data to ViewModel

Identical pattern to `ListDetailViewModel`. The VM receives task and list arrays via an `update(with:tasks:lists:now:)` method.

```swift
@Observable
final class ReminderSegmentViewModel {
    private(set) var filteredTasks: [TaskItem] = []
    private(set) var groupedSections: [TaskUIModel.DatedSection] = []
    // ...

    func update(with tasks: [TaskItem], lists: [ReminderList], now: Date) {
        self.filteredTasks = ReminderSegmentLogic.filteredTasks(tasks, for: segment, now: now)
        self.groupedSections = ReminderSegmentLogic.datedSections(from: tasks, for: segment, now: now)
        // ...
    }
}
```

**Rationale:** Same as ListDetail — `@Query` can't live in the VM. Passing data in keeps the VM testable and the view as the SwiftData boundary.

### 2. `@Observable` over `ObservableObject`

Match the existing `AppState` pattern and the companion `ListDetailViewModel`.

### 3. ViewModel holds `modelContext` and `segment`

```swift
@Observable
final class ReminderSegmentViewModel {
    private let modelContext: ModelContext
    let segment: ReminderSegment

    init(modelContext: ModelContext, segment: ReminderSegment, overdueTasks: [TaskItem] = []) { ... }
}
```

### 4. Single `update()` entry point

The view calls `viewModel.update(...)` on appear and whenever data changes. The VM recomputes all derived state (filtered, sorted, grouped, upcoming groups) in one pass.

**Rationale:** Simple, predictable, no reactive pipeline complexity. The compute is light (filter + sort on < 1000 items).

### 5. Quick capture, completion, scheduling, and timer are VM methods

```swift
func commitQuickCapture(text: String, captureDate: Date?) -> TaskItem?
func toggleCompletion(for task: TaskItem)
func scheduleTask(_ task: TaskItem, dueDate: Date?, hasTime: Bool)
func rescheduleToToday(_ task: TaskItem)
func rescheduleToTomorrow(_ task: TaskItem)
func rescheduleToLater(_ task: TaskItem)
```

The timer refresh (`Timer.publish`) stays in the view (it's a SwiftUI concern), but the VM exposes a `func refreshNow() { now = Date() }` that the view calls via `.onReceive`.

### 6. Overdue state management moves to VM

`showOverdue`, `overdueTasks` become VM properties rather than view state. The view passes `overdueTasks` at init or via the `update()` call.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Large ViewModel**: 714 lines → ~400 lines in VM + ~250 lines in view | Acceptable split. If VM grows further, extract sub-logic back into `ReminderSegmentLogic`. |
| **Performance from single update()**: Recomputes grouped sections on every change | Grouping is pure computation over an array. Negligible cost. Vastly cheaper than a view rerender. |
| **Regressions in segment-specific behavior**: Each segment has unique rendering (overdue on Today, month groups on Upcoming, etc.) | The VM only handles data processing — segment-specific view branching stays in the view. View's job is to render, VM's job is to compute. |
| **Timer refresh**: Timer is a SwiftUI `@State` concern | Keep `Timer.publish` + `.onReceive` in the view. The view calls `viewModel.refreshNow()` to update the VM's `now` date. |
