## 1. Extract shared utility

- [ ] 1.1 Create `TaskFlow/Utilities/DateRounding.swift` with public `nearestRoundedHour(from:)` function
- [ ] 1.2 Update `ReminderEditorView` to use shared utility, remove private `nearestRoundedHour()` duplicate

## 2. Create TaskScheduleDatePickerViewModel

- [ ] 2.1 Create `TaskFlow/Features/Reminders/ViewModels/TaskScheduleDatePickerViewModel.swift` with `@Observable` class
- [ ] 2.2 Add `dueDate`, `hasTime`, `expandedPicker` properties
- [ ] 2.3 Add `init(initialDueDate:)` matching current init logic
- [ ] 2.4 Add `toggleDate(isEnabled:)` with date defaulting and picker state
- [ ] 2.5 Add `toggleTime(isEnabled:)` with rounding logic

## 3. Refactor TaskScheduleDatePickerSheet to use ViewModel

- [ ] 3.1 Create VM from `initialDueDate`
- [ ] 3.2 Replace all `@State` properties with VM bindings
- [ ] 3.3 Wire "Done" button to call `onCommit(vm.dueDate, vm.hasTime)`
- [ ] 3.4 Remove `nearestRoundedHour()` private method (now uses shared utility)

## 4. Verify

- [ ] 4.1 Build succeeds with no warnings
- [ ] 4.2 Schedule sheet opens with correct initial state
- [ ] 4.3 Date toggle works correctly
- [ ] 4.4 Time toggle rounds to nearest half hour
- [ ] 4.5 Cancel dismisses with no changes
- [ ] 4.6 Done commits selected date/time
- [ ] 4.7 ReminderEditorView still compiles and works
