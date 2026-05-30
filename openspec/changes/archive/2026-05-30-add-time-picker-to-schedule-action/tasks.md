## 1. Rewrite `TaskScheduleDatePickerSheet`

- [x] 1.1 Add local `@State var dueDate: Date?` and `@State var hasTime: Bool` initialized from task's existing dueDate
- [x] 1.2 Add date toggle row with subtitle showing selected date, expanding graphical DatePicker inline when active
- [x] 1.3 Implement date toggle on/off behavior: on sets dueDate to today, off clears dueDate and hasTime
- [x] 1.4 Add time toggle row with subtitle showing selected time, expanding wheel TimePicker inline when active
- [x] 1.5 Implement time toggle on/off: on auto-enables date with nearest rounded half-hour, off only clears hasTime
- [x] 1.6 Add mutual exclusion between date and time picker expansions
- [x] 1.7 Implement Cancel button to discard local state and restore original task dueDate
- [x] 1.8 Implement Done button to commit dueDate/hasTime state to the task

## 2. Update `ReminderSegmentDetailView`

- [x] 2.1 Update sheet binding: replace `Date` binding with an optional that supports nil (date off)
- [x] 2.2 Adjust `presentScheduleSheet` to pass existing task's dueDate info (including time component)
- [x] 2.3 Handle `hasTime` semantics: strip time on commit when hasTime is false

## 3. Verify & Clean Up

- [x] 3.1 Build the project and verify no compilation errors
- [x] 3.2 Run existing unit tests to confirm no regressions
- [x] 3.3 Run UI tests to confirm no regressions
