## 1. Date helper statics

- [x] 1.1 Add `static func nextSaturday(from date: Date) -> Date` to `ReminderSegmentViewModel` (returns today when already Sat/Sun, else the next Saturday)
- [x] 1.2 Add `static func nextMonth(from date: Date) -> Date` to `ReminderSegmentViewModel` (same day-of-month next month, clamped to the month's last day on overflow)

## 2. Single-task reschedule methods

- [x] 2.1 `TimelineViewModel`: add `rescheduleToThisWeekend`, `rescheduleToNextMonth`; rename `rescheduleToLater` → `rescheduleToNone`
- [x] 2.2 `DetailViewModel`: add `rescheduleTaskToThisWeekend`, `rescheduleTaskToNextMonth`; rename `rescheduleTaskToLater` → `rescheduleTaskToNone`
- [x] 2.3 Remove the now-unused `canMoveToToday` / `canMoveToTomorrow` / `canMoveToNextWeek` from `TimelineViewModel` and `DetailViewModel`

## 3. Bulk reschedule methods

- [x] 3.1 `TimelineViewModel`: rename `bulkRescheduleToLater` → `bulkRescheduleToNone`; add `bulkRescheduleToThisWeekend` and `bulkRescheduleToNextMonth`
- [x] 3.2 `DetailViewModel`: same renames/additions
- [x] 3.3 Add `bulkRescheduleToDate(_ taskIDs: Set<PersistentIdentifier>, dueDate: Date?, hasTime: Bool)` to `TimelineViewModel` and `DetailViewModel` (applies `scheduleTask` logic per task)

## 4. Schedule sheet auto-focus

- [x] 4.1 `TaskScheduleDatePickerViewModel`: add `initialFocus: ExpandedPicker?` init parameter; use it as the initial `expandedPicker` instead of the `initialDueDate != nil ? .date : nil` heuristic
- [x] 4.2 `TaskScheduleDatePickerSheet`: add `initialFocus` init parameter and pass it to the ViewModel

## 5. TaskRowView menu restructure

- [x] 5.1 Define `enum DueDateAction { case none, today, tomorrow, thisWeekend, nextWeek, nextMonth, custom }`
- [x] 5.2 Replace `onMoveToToday` / `onMoveToTomorrow` / `onMoveToNextWeek` / `onMoveToLater` / `onSchedule` on `TaskRowView` with a single `onDueDateAction: ((DueDateAction) -> Void)?`
- [x] 5.3 Add `onMoveUp` / `onMoveDown` optional callbacks to `TaskRowView`
- [x] 5.4 Rebuild the context menu: remove the flat Today/Tomorrow/Next Week/Later/Schedule items; add a `Menu("Due Date")` listing None, Today, Tomorrow, This Weekend, Next Week, Next Month, divider, Custom…
- [x] 5.5 Delete the dead `TaskNodeView` wrapper (only consumer of the removed callbacks)

## 6. View call-site updates

- [x] 6.1 `TimelineView` `taskListRow`: wire `onDueDateAction` mapping to the new VM methods and `.custom` → schedule sheet; remove `canMoveTo*` gating
- [x] 6.2 `DetailView` `taskListRow`: same wiring changes
- [x] 6.3 `TimelineView` + `DetailView`: present a reused `TaskScheduleDatePickerSheet` for `onRescheduleCustom` (new `BulkScheduleConfig { taskIDs }` state) committing to `bulkRescheduleToDate`
- [x] 6.4 `CompletedView`: update its `BulkActionsToolbar` call to the renamed/added callbacks (no-op stubs)

## 7. BulkActionsToolbar

- [x] 7.1 Rename `onRescheduleLater` → `onRescheduleNone`; add `onRescheduleThisWeekend` and `onRescheduleNextMonth`
- [x] 7.2 Rebuild the Date menu as: Today, Tomorrow, This Weekend, Next Week, Next Month, divider, Pick a Date…, None

## 8. Subtask context menu (editor)

- [x] 8.1 `ReminderEditorViewModel`: add subtask `rescheduleTo*` + `scheduleTask` methods, `moveSubtask(_:to:)` (sets `parentTask = nil`, `reminderList`, sort order), and `moveSubtaskUp` / `moveSubtaskDown` (swap sort order with adjacent sibling)
- [x] 8.2 `EditorView` subtask section: wire `onDueDateAction`, `onMoveToList` (sections from `reminderLists` via `buildListSections`), `onMoveUp`/`onMoveDown` (hidden when only one sibling), and `onDelete` on the subtask `TaskRowView`
- [x] 8.3 `EditorView`: add a schedule-sheet presenter for subtask `.custom`; set `showsDueDate: true` on subtask rows

## 9. Restore dated subtasks in segment views

- [x] 9.1 `TimelineViewModel`: segment filters include subtasks with a due date (roots OR `parentTask != nil && dueDate != nil`) so dated subtasks surface flat at depth 0
- [x] 9.2 Upcoming group construction: change the `parentTask == nil` filter to also include dated subtasks
- [x] 9.3 Overdue display tasks include dated subtasks in the Overdue section

## 10. Spec / docs cleanup

- [x] 10.1 Reword the `app-mental-model` base spec "Dead code" section: the preserved "Later" label note is replaced by the flat presets / "More" submenu / "No Date" description

## 10b. Intelligent context menu (added mid-implementation)

- [x] 10b.1 Flatten presets: flat Today / Tomorrow / This Weekend; "No Date" above "More"; "More" submenu (Next Week / Next Month / Custom…)
- [x] 10b.2 State-aware due-date items in `TaskRowView`: omit the preset matching the task's current due date; show "No Date" only when a date exists
- [x] 10b.3 Context-aware "Move to List": exclude the task's own list for root tasks (`excludedListID` passed by `TimelineView` / `DetailView`); subtask rows keep every list (parent's list = promote)
- [x] 10b.4 Update all spec deltas (task-due-date-menu, subtask-context-menu, app-mental-model) + base spec, proposal, and design for the new menu shape and state-aware behavior

## 11. Tests

- [x] 11.1 Unit tests for `nextSaturday(from:)` and `nextMonth(from:)` (including weekend and overflow-clamp cases)
- [x] 11.2 Unit tests for `rescheduleToNone` / `rescheduleToThisWeekend` / `rescheduleToNextMonth` + bulk variants in both ViewModels
- [x] 11.3 Unit tests for `EditorViewModel` `moveSubtaskUp` / `moveSubtaskDown` (boundary no-op, single-sibling) and `moveSubtask(_:to:)` (un-nest + promote-in-place)
- [x] 11.4 Update `ReminderSegmentViewModelTests` for dated-subtask surfacing in segment filters
- [~] 11.5 Build the app and run the full test suite (`xcodebuild test`), fixing any regressions — app and test bundle compile (`xcodebuild build` and `build-for-testing` both **BUILD SUCCEEDED**); full `test` run blocked by simulator resource errors (NSPOSIXErrorDomain Code=35), test execution still pending
