## Context

`CompletedView` (181 lines) shows tasks completed within the last 30 days, grouped by Today/Yesterday/This Week/Earlier. It has three operations: un-complete (restore with notification rescheduling), tap-to-edit, and swipe-to-delete. The grouping logic and destination label helper are the most substantial pieces.

## Goals / Non-Goals

**Goals:**
- Extract `CompletedViewModel` as an `@Observable` class owning completed task filtering, grouping, and mutations
- VM owns: `recentCompletedTasks`, `groupedTasks`, `uncomplete(_:)`, `delete(_:)`, `destinationLabel(for:)`
- View retains: `@Query`, `editingTask` for sheet presentation, body rendering

**Non-Goals:**
- Changing the 30-day cutoff or grouping logic
- Altering the UI layout of task rows or empty state
- Adding batch operations or clear-all

## Decisions

### 1. Single update entry point

```swift
func update(tasks: [TaskItem]) {
    self.recentCompletedTasks = Self.computeRecentTasks(tasks)
    self.groupedTasks = Self.computeGroupedTasks(self.recentCompletedTasks)
}
```

Same pattern as other ViewModels. View calls `update(...)` on appear and when data changes.

### 2. Grouping and label logic are static VM methods

```swift
static func computeGroupedTasks(_ tasks: [TaskItem]) -> [(String, [TaskItem])]
static func destinationLabel(for task: TaskItem) -> String
```

**Rationale:** These are pure functions with no side effects. Making them static enables direct unit testing without VM instantiation.

### 3. Un-complete restores notification

```swift
func uncomplete(_ task: TaskItem) {
    task.isCompleted = false
    task.completionDate = nil
    if task.safeHasTime {
        NotificationService.shared.schedule(for: task)
    }
}
```

Matches current view logic exactly. Notification handling moves to VM.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Static methods duplicate logic** if grouping changes | Grouping is specific to completed view. If reused elsewhere, extract to shared helper. |
