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

- [x] 5.1 Define `enum DueDateAction { case none, today, tomorrow, thisWeekend, nextWeek, custom }`
- [x] 5.2 Replace `onMoveToToday` / `onMoveToTomorrow` / `onMoveToNextWeek` / `onMoveToLater` / `onSchedule` on `TaskRowView` with a single `onDueDateAction: ((DueDateAction) -> Void)?`
- [x] 5.3 Add `onMoveUp` / `onMoveDown` optional callbacks to `TaskRowView`
- [x] 5.4 Rebuild the context menu: remove the flat Today/Tomorrow/Next Week/Later/Schedule items; add a `Menu("Deadline")` listing None, a divider, then Today, Tomorrow, This Weekend, Next Week, Custom…
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

- [x] 10.1 Reword the `app-mental-model` base spec "Dead code" section: the preserved "Later" label note is replaced by the single "Deadline" submenu / "None" description

## 10b. Intelligent context menu (added mid-implementation)

- [x] 10b.1 Group all due-date actions under a single "Deadline" submenu (Apple Reminders approach — every date action is two taps): Today / Tomorrow / This Weekend / Next Week / Next Month / Custom… / None
- [x] 10b.2 State-aware due-date items in `TaskRowView`: omit the preset matching the task's current due date; show "None" only when a date exists
- [x] 10b.3 Context-aware "Move to List": exclude the task's own list for root tasks (`excludedListID` passed by `TimelineView` / `DetailView`); subtask rows keep every list (parent's list = promote)
- [x] 10b.4 Update all spec deltas (task-due-date-menu, subtask-context-menu, app-mental-model) + base spec, proposal, and design for the new menu shape and state-aware behavior

## 10c. Menu restructure: single "Deadline" submenu (added mid-implementation)

- [x] 10c.1 Push the date presets off the top level: all date actions (Today / Tomorrow / This Weekend / Next Week / Next Month / Custom…, divider, None) nest under "Deadline" so nothing about the due date stays flat
- [x] 10c.2 Rename the submenu label from "More" to "Deadline" (Apple Reminders term for the due field)
- [x] 10c.3 Rename the clearing action "No Date" → "None" and place it after a divider at the bottom of the "Deadline" submenu (the only action that clears the date, so it is visually distinct from the date-setting presets)
- [x] 10c.4 Update spec deltas (task-due-date-menu, subtask-context-menu, app-mental-model), base `app-mental-model` spec, proposal, and design for the single nested "Deadline" menu

## 10d. Remove the Next Month preset (added mid-implementation)

- [x] 10d.1 Drop "Next Month" from the "Deadline" submenu — further-out dates are picked via Custom… / "Pick a Date…" instead
- [x] 10d.2 Reorder the "Deadline" submenu: "None" first (only when dated), divider, then Today / Tomorrow / This Weekend / Next Week / Custom…
- [x] 10d.3 Remove Next Month from the bulk Date menu (`onRescheduleNextMonth`) and its call sites (`TimelineView`, `DetailView`, `CompletedView`)
- [x] 10d.4 Delete the now-unused `rescheduleToNextMonth` / `rescheduleTaskToNextMonth` / `bulkRescheduleToNextMonth` methods and the `nextMonth(from:)` helper; drop the `.nextMonth` case from `DueDateAction`, `presetIsRedundant`, the views' switches, and `EditorViewModel`
- [x] 10d.5 Remove the `nextMonth` tests from `ReschedulePresetTests` and `DueDatePresetTests`
- [x] 10d.6 Update spec deltas (task-due-date-menu, subtask-context-menu, app-mental-model), base `app-mental-model` spec, proposal, and design for the removal

## 10e. Active-item checkmark + calendar-day preset icons (added mid-implementation)

- [x] 10e.1 Replace the state-aware preset hiding (`presetIsRedundant`) with an active-item checkmark: "None" ticked when `task.dueDate == nil`, the matching preset ticked when its target day equals the due date (compared at `startOfDay`, time ignored), Custom… ticked for any other date; no item is ever hidden
- [x] 10e.2 Move "None" to the top of the "Deadline" submenu, always listed, followed by a `Divider()`; ticked with a `checkmark` label when the task has no due date, plain text otherwise
- [x] 10e.3 Give each preset row a leading mini calendar icon (SF Symbol "calendar" + small bold day-of-month): Today → today, Tomorrow → tomorrow, This Weekend → `nextSaturday`, Next Week → `nextMonday`; None and Custom… get no day number
- [x] 10e.4 Update spec deltas (task-due-date-menu, subtask-context-menu, app-mental-model), base `app-mental-model` spec, proposal, and design for the checkmark + calendar-icon menu

## 11. Tests

- [x] 11.1 Unit tests for `nextSaturday(from:)` (including weekend cases)
- [x] 11.2 Unit tests for `rescheduleToNone` / `rescheduleToThisWeekend` + bulk variants in both ViewModels
- [x] 11.3 Unit tests for `EditorViewModel` `moveSubtaskUp` / `moveSubtaskDown` (boundary no-op, single-sibling) and `moveSubtask(_:to:)` (un-nest + promote-in-place)
- [x] 11.4 Update `ReminderSegmentViewModelTests` for dated-subtask surfacing in segment filters
- [~] 11.5 Build the app and run the full test suite (`xcodebuild test`), fixing any regressions — app and test bundle compile (`xcodebuild build` and `build-for-testing` both **BUILD SUCCEEDED**); full `test` run blocked by simulator resource errors (NSPOSIXErrorDomain Code=35), test execution still pending
