## 1. Decouple Time toggle from date dependency

- [x] 1.1 Remove `.disabled(draft.dueDate == nil)` modifier on the Time Toggle in `ReminderEditorView.swift`
- [x] 1.2 No change needed — `nearestRoundedHour()` already correctly sets today date + rounded time
- [x] 1.3 Verify the time row `DragGesture.onChanged` and `.onEnded` guards are gated on `draft.hasTime` only (not `draft.dueDate`) — these are already correct

## 2. Verify

- [x] 2.1 Build the project and confirm no compilation errors
- [x] 2.2 Run the app and verify: Time toggle is interactive when Date toggle is off
- [x] 2.3 Verify enabling Time without a date auto-sets the date to today
- [x] 2.4 Verify enabling Time with an existing date does not override it
- [x] 2.5 Verify toggling Time off does not clear the date
