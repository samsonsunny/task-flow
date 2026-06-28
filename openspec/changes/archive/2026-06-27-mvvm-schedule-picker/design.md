## Context

`TaskScheduleDatePickerSheet` (182 lines) is a reusable sheet for setting task dates. It's used from both `ListDetailView` and `ReminderSegmentDetailView`. It manages `dueDate`, `hasTime`, and `expandedPicker` state locally with `@State`. The `nearestRoundedHour()` function is duplicated identically in `ReminderEditorView`.

The sheet uses a callback pattern (`onCommit: (Date?, Bool) -> Void`) rather than a model mutation — the parent view decides what to do with the result.

## Goals / Non-Goals

**Goals:**
- Extract `TaskScheduleDatePickerViewModel` owning all date/time state and picker expansion logic
- Extract `nearestRoundedHour()` to `Utilities/DateRounding.swift` as a free function
- Wire `ReminderEditorView` to use the shared utility, removing the private duplicate
- View retains: binding to VM properties, commit callback invocation, sheet presentation

**Non-Goals:**
- Changing the callback-based communication pattern with parent views
- Altering sheet UI, detents, or animation behavior
- Changing how parent views handle the commit result

## Decisions

### 1. ViewModel owns local state only

```swift
@Observable
final class TaskScheduleDatePickerViewModel {
    var dueDate: Date?
    var hasTime: Bool
    var expandedPicker: ExpandedPicker?

    init(initialDueDate: Date?) { ... }
}
```

**Rationale:** The VM manages only the state that is currently in `@State`. The commit callback remains the interface to the parent — the view calls `onCommit(vm.dueDate, vm.hasTime)` when done.

### 2. `nearestRoundedHour()` extracted as free function

```swift
// Utilities/DateRounding.swift
public func nearestRoundedHour(from date: Date = Date()) -> Date { ... }
```

Both `TaskScheduleDatePickerSheet` and `ReminderEditorView` use this. The editor's private method is removed in favor of the shared utility.

### 3. Init logic matches current view

```swift
init(initialDueDate: Date?) {
    let hasTimeVal: Bool
    if let date = initialDueDate {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        hasTimeVal = components.hour != 0 || components.minute != 0
    } else {
        hasTimeVal = false
    }
    self.hasTime = hasTimeVal
    self.dueDate = initialDueDate
    self.expandedPicker = initialDueDate != nil ? .date : nil
}
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Small VM for small view**: 182 lines, VM might double file count | The VM + shared utility extraction is primarily about deduplication and consistency across the 5 other proposals. The testability gain for the rounding logic is a bonus. |
