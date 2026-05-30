## Context

The `TaskScheduleDatePickerSheet` is a modal sheet presented from `ReminderSegmentDetailView` when the user taps "Schedule" in a task's context menu. It currently shows a graphical date-only picker with Cancel/Done buttons. The `ReminderEditorView` offers a richer schedule section with Date/Time toggles and inline expandable pickers (graphical date, wheel time). The schedule sheet needs to provide a comparable experience so users can set both date and time from the context menu without opening the full editor.

**Current architecture:**
- `TaskScheduleDatePickerSheet` — 48 lines, date-only `.graphical` picker, medium/large detents
- `ReminderSegmentDetailView` — holds `taskBeingScheduled`, `taskScheduleChosenDate`, `isTaskScheduleSheetPresented` state; passes `chosenDate` binding to the sheet
- `onChooseDate` closure mutates `taskBeingScheduled?.dueDate` directly (SwiftData auto-save)
- No time support exists in this flow

## Goals / Non-Goals

**Goals:**
- Replace the date-only picker sheet with date + time toggle controls and inline pickers
- Allow users to toggle date on/off (nil when off)
- Allow users to toggle time on/off (auto-enables date when time is turned on)
- Use graphical date picker and wheel time picker matching ReminderEditorView
- Preserve existing task's dueDate/time when opening the sheet
- Keep sheet presentation style (medium/large detents with Cancel/Done toolbar)

**Non-Goals:**
- No changes to ReminderEditorView or ReminderDraft
- No data model changes
- No changes to the context menu items themselves (Today, Tomorrow, Later, Schedule remain)
- No changes to swipe actions or other task row interactions

## Decisions

**1. Rewrite TaskScheduleDatePickerSheet vs. reuse ReminderEditorView's schedule section**
- **Decision**: Rewrite `TaskScheduleDatePickerSheet` with its own date/time toggle UI (not reusing `ReminderEditorView`)
- **Rationale**: The sheet has a different container (NavigationStack with Cancel/Done toolbar), different detents, and directly mutates `TaskItem.dueDate` rather than using a `ReminderDraft` draft model. Extracting `ReminderEditorView`'s schedule section into a reusable component would be a larger refactor with no clear benefit since the behavior is similar but the lifecycle differs.
- **Alternative considered**: Extract a shared `SchedulePickerView` component. Rejected because the sheet's Done/Cancel commit semantics differ from the editor's auto-save-on-change approach, and the editor ties into `ReminderDraft` state management.

**2. Sheet state management: use local draft state vs. direct bindings**
- **Decision**: Introduce local `@State var dueDate: Date?` and `@State var hasTime: Bool` inside the sheet, initialized from the task's existing `dueDate`. Commit to the task only on "Done".
- **Rationale**: The current sheet commits changes immediately on `onChooseDate`. With the toggle-off-date capability, we need a cancel-discard behavior (if user toggles date off then taps Cancel, the task should remain unchanged). Local state allows discard without side effects.
- **Alternative considered**: Continue mutating `chosenDate` binding and let `onChooseDate` handle commit. Rejected because `chosenDate` is `Date` (non-optional) and cannot represent "no date".

**3. Date picker style: graphical vs. compact**
- **Decision**: Use `.graphical` for date picker and `.wheel` for time picker, matching `ReminderEditorView`
- **Rationale**: Consistency across the app. Users familiar with the new reminder view will find the same controls in the schedule sheet.

**4. Toggle auto-enable behavior matching**
- **Decision**: Match `ReminderEditorView`'s exact toggle behavior: turning off date clears time too; turning on time auto-enables date with nearest rounded half-hour.
- **Rationale**: This is documented in the existing `reminder-deadline-time` spec and already implemented in `ReminderEditorView`. Consistent behavior reduces user confusion.

## Risks / Trade-offs

- **Risk**: Sheet height grows with two inline pickers → **Mitigation**: Use `.medium` detent as default; pickers expand within the sheet with scrolling. The DatePicker + TimePicker height (~400pt) fits within `.medium` detent (~half screen).
- **Risk**: Users may accidentally toggle date off and lose the date → **Mitigation**: Cancel button discards changes, reverting to original task state.
- **Trade-off**: Local state duplication (storing `dueDate` and `hasTime` in the sheet) vs. directly binding to the task. Local state chosen for discard safety, at the cost of slight complexity.
