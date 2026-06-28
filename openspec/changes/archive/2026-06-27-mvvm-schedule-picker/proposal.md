## Why

`TaskScheduleDatePickerSheet` (182 lines) manages schedule state (date, time, expanded picker) and shares `nearestRoundedHour()` logic duplicated in `ReminderEditorView`. Extracting a ViewModel makes the scheduling state testable and eliminates the duplicate utility function.

## What Changes

- Create `TaskScheduleDatePickerViewModel` as an `@Observable` class owning `dueDate`, `hasTime`, `expandedPicker`, and date/time rounding logic
- `TaskScheduleDatePickerSheet` becomes a thin consumer: observes VM state, delegates commit to the VM
- Extract `nearestRoundedHour()` to a shared utility in `Utilities/DateRounding.swift` for reuse across the picker and editor
- The existing `onCommit` callback pattern is preserved — the VM computes the final values, the view delivers them

## Capabilities

### New Capabilities
- `schedule-picker-view-model`: ViewModel for `TaskScheduleDatePickerSheet` owning date/time state, expanded picker tracking, and date rounding

### Modified Capabilities
*None.*

## Impact

- **New file**: `TaskFlow/Features/Reminders/ViewModels/TaskScheduleDatePickerViewModel.swift`
- **New file**: `TaskFlow/Utilities/DateRounding.swift` — shared `nearestRoundedHour()` utility
- **Modified**: `TaskScheduleDatePickerSheet.swift` — reduced from ~182 lines to ~100 lines
- **Modified**: `ReminderEditorView.swift` — uses shared utility instead of private duplicate
