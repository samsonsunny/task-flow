## 1. Upcoming View State Refactor

- [x] 1.1 Replace `isQuickCapturing: Bool` with `activeCaptureDate: Date?` in ReminderSegmentDetailView
- [x] 1.2 Rename `quickCaptureText` and `isQuickCaptureFocused` to be shared by new per-section field
- [x] 1.3 Update `commitQuickCapture()` to read `activeCaptureDate` for `dueDate` instead of `contextualDate`
- [x] 1.4 Guard commit: return early if `activeCaptureDate` is nil

## 2. Upcoming View CTA Conversions

- [x] 2.1 Convert `addReminderButton(date:)` tap: set `activeCaptureDate` + focus instead of setting `newReminderConfig`
- [x] 2.2 Convert `dayHeader` tap: set `activeCaptureDate` instead of setting `newReminderConfig`
- [x] 2.3 Convert `emptyDayRow` tap: set `activeCaptureDate` instead of setting `newReminderConfig`
- [x] 2.4 Convert month sub-section day taps: set `activeCaptureDate` instead of setting `newReminderConfig`
- [x] 2.5 Convert `monthSectionView` header tap: set `activeCaptureDate` instead of setting `newReminderConfig`

## 3. Upcoming View Inline Field Rendering

- [x] 3.1 Remove the top-of-list `if isQuickCapturing { quickCaptureRow }` from the `.upcoming` branch
- [x] 3.2 Render `quickCaptureRow` conditionally inside each day section when `activeCaptureDate == date`
- [x] 3.3 Render `quickCaptureRow` conditionally inside each month sub-section day group when `activeCaptureDate == date`
- [x] 3.4 Show/hide the "Add Reminder" button in a section based on whether that section's inline field is active
- [x] 3.5 Add a date hint label to the quick capture row (e.g. "→ Thu, Jun 25") showing the active date

## 4. List Detail View Inline Capture

- [x] 4.1 Add `isQuickCapturing: Bool`, `quickCaptureText: String`, `isQuickCaptureFocused: FocusState` state to ListDetailView
- [x] 4.2 Change floating `+` action: set `isQuickCapturing = true` and focus instead of setting `newReminderConfig`
- [x] 4.3 Add inline quick capture row rendering at top of the List body in ListDetailView
- [x] 4.4 Implement `commitQuickCapture()` in ListDetailView: create task with current list ID, no due date
- [x] 4.5 Implement `openQuickCaptureEditor()` in ListDetailView: open sheet with `initialListID` pre-filled
- [x] 4.6 Add swipe-to-cancel behavior on the inline field in ListDetailView
- [x] 4.7 Dismiss capture bar when focus is lost in ListDetailView

## 5. Verification

- [x] 5.1 Build and run: verify Upcoming view renders correctly with per-day inline fields
- [x] 5.2 Verify Today/Tomorrow/Later/Overdue inline capture unchanged
- [x] 5.3 Verify ListDetailView inline capture creates tasks in the correct list
- [x] 5.4 Verify single-field-at-a-time constraint works across Upcoming sections
- [x] 5.5 Verify chevron opens full editor with correct contextual defaults
- [x] 5.6 Verify swipe-to-cancel dismisses field and discards text
- [x] 5.7 Focus-loss dismissal works in both views
- [x] 5.8 Only Add Reminder button (dashed circle) triggers inline in Upcoming; headers/empty rows open sheet
