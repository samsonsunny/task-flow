# quick-capture

## Purpose

Define how tasks are captured across all contexts: the floating + button's context-aware defaults, the shared inline quick-capture row in list and segment views, per-day capture in Upcoming, and hand-off to the full editor.

Consolidates (2026-08): `contextual-task-creation`, `list-inline-capture`, `upcoming-inline-capture`.

## Requirements

### Requirement: Context-aware + button
The floating + button SHALL create tasks with context-appropriate defaults based on the currently active tab and sidebar selection.

#### Scenario: + on Today tab
- **WHEN** user is on the Today tab and taps the + button
- **THEN** a new task is created with `dueDate = today`
- **AND** the task is assigned to the currently selected sidebar list (or Inbox list if none selected)

#### Scenario: + on Tomorrow tab
- **WHEN** user is on the Tomorrow tab and taps the + button
- **THEN** a new task is created with `dueDate = tomorrow`
- **AND** the task is assigned to the currently selected sidebar list (or Inbox list if none selected)

#### Scenario: + on Upcoming tab
- **WHEN** user is on the Upcoming tab and taps the + button
- **THEN** the task editor opens with the date picker shown
- **AND** no default date is pre-filled

#### Scenario: + with a list selected in sidebar
- **WHEN** user has selected a list in the sidebar and taps the + button on any tab
- **THEN** the task is assigned to that list
- **AND** if on a date tab, the date is also set per the tab context
- **AND** if on Upcoming tab, the date is left unset

### Requirement: Quick capture row
After tapping +, a quick capture text field SHALL appear inline at the top of the task list (similar to Reminders.app) for all segments EXCEPT Upcoming. For the Upcoming segment, the floating + SHALL open the full editor instead. The task SHALL be created on return/submit with the contextual defaults applied.

#### Scenario: Quick capture saves with defaults
- **WHEN** user types text in the quick capture field and presses return
- **AND** the current segment is not Upcoming
- **THEN** a new task is created with that text and the contextual date/list defaults
- **AND** the quick capture field clears and remains ready for the next entry

#### Scenario: Quick capture date is visible
- **WHEN** a task is created via quick capture on the Today tab
- **THEN** the task row shows today's date (or "Today") as a visual hint

#### Scenario: Quick capture not available in Upcoming
- **WHEN** user is on the Upcoming tab and taps the floating +
- **THEN** the full ReminderEditorView opens
- **AND** no inline quick capture field appears

### Requirement: Editor still available for full detail
If user needs to set more than just the title (e.g., list, notes, priority), the quick capture SHALL support tapping a detail disclosure button to open the full editor.

#### Scenario: Open editor from quick capture
- **WHEN** user taps the detail disclosure button next to the quick capture field
- **THEN** the full ReminderEditorView opens with the contextual defaults pre-filled

### Requirement: Editor supports subtask creation
The `ReminderEditorView` SHALL provide a "Add Subtask" control that allows creating subtasks for the task being edited. Subtask creation SHALL be available in both new-task and edit-task modes.

#### Scenario: Add subtask in editor
- **WHEN** user opens `ReminderEditorView` for a task
- **AND** taps "Add Subtask"
- **THEN** a text field SHALL appear for entering the subtask title
- **AND** on submit, a new `TaskItem` is created with `parentTask` set to the current task
- **AND** the subtask inherits the parent's `reminderList` and default date

### Requirement: Inline quick capture in ListDetailView
The system SHALL provide inline quick capture in ListDetailView when the user taps the floating `+` button. The inline text field SHALL appear as the last row inside the task List. Committing the field SHALL create a task assigned to the current list with no date. Newly created tasks SHALL appear directly above the quick capture field.

#### Scenario: Tapping + reveals inline field at bottom with auto-scroll
- **WHEN** the user is viewing a list in ListDetailView
- **AND** taps the floating `+` button
- **THEN** the list auto-scrolls to the bottom
- **AND** an inline text field appears as the last row in the List, below all tasks
- **AND** the text field is focused for immediate input
- **AND** the full editor sheet is NOT opened

#### Scenario: Committing inline field creates task for current list
- **WHEN** the user types text in the inline field and presses return
- **THEN** a new task is created with that text
- **AND** the task's `reminderList` is set to the current list
- **AND** the task has no `dueDate`
- **AND** the new task appears directly above the inline field
- **AND** the inline field clears and remains focused for rapid entry
- **AND** the keyboard stays visible for continued input

#### Scenario: Tapping away dismisses inline field
- **WHEN** the user taps outside the quick capture field after entering text
- **THEN** the text is committed as a new task if non-empty
- **AND** the inline field is dismissed

#### Scenario: Empty commit is ignored
- **WHEN** the user presses return on an empty inline field
- **THEN** no task is created
- **AND** the inline field is dismissed

#### Scenario: Tapping + while field is active refocuses it
- **WHEN** the user taps the floating `+` button while the quick capture field is already active
- **THEN** the field remains visible and gains focus
- **AND** the list scrolls to the bottom if not already there

### Requirement: Inline quick capture in Today/Tomorrow views
The system SHALL provide inline quick capture in ReminderSegmentDetailView for Today and Tomorrow segments when the user taps the floating `+` button. The inline text field SHALL appear as the last row inside the section's List content. Committing the field SHALL create a task with the segment's date. Newly created tasks SHALL appear above the quick capture field.

Tasks within Today/Tomorrow SHALL be sorted by `createdAt` ascending (oldest first) so that newly created tasks appear adjacent to and above the quick capture field at the bottom of the list.

#### Scenario: Tapping + reveals inline field at bottom
- **WHEN** the user is viewing Today or Tomorrow
- **AND** taps the floating `+` button
- **THEN** the list auto-scrolls to the bottom
- **AND** an inline text field appears as the last row in the section
- **AND** the text field is focused for immediate input
- **AND** a date hint ("→ Today" / "→ Tomorrow") is shown below the field

#### Scenario: Committing creates task with segment date
- **WHEN** the user types text and presses return
- **THEN** a new task is created with that text
- **AND** the task's `dueDate` is set to the segment's date
- **AND** the new task appears above the inline field (adjacent to it at the bottom of the list)
- **AND** the field clears and remains focused
- **AND** the keyboard stays visible for continued input

#### Scenario: Tap-away dismisses field
- **WHEN** the user taps outside the field
- **THEN** text is committed if non-empty
- **AND** the field is dismissed

### Requirement: Inline quick capture in Upcoming views
The system SHALL provide per-day inline quick capture in the Upcoming segment. Each day section SHALL have its own inline field or "Add Reminder" CTA, positioned at the bottom of that section's content.

Tasks within each Upcoming day section SHALL be sorted by `createdAt` ascending (oldest first) so that newly created tasks appear adjacent to and above the per-day inline field.

The per-day inline field in Upcoming SHALL use the same `QuickCaptureRow` component as other views. The field's `onSubmit` SHALL commit the task with the specific day's date via `commitQuickCaptureWithDate`.

#### Scenario: Per-day inline field within each section
- **WHEN** the user taps a day header or "Add Reminder" button
- **THEN** an inline text field appears within that day's section
- **AND** the field is positioned at the bottom of the section's task list
- **AND** committing creates a task with that specific date
- **AND** the new task appears above the inline field within that day section

### Requirement: Shared QuickCaptureRow component
The system SHALL use a shared `QuickCaptureRow` component (defined in `Views/Components/QuickCaptureRow.swift`) for all inline quick capture fields. The component SHALL:

- Accept `@Binding text`, `@FocusState.Binding isFocused`, `onSubmit` callback, and optional `dateHint`
- Render as a row with a filled circle and text field
- Show the date hint label below the field when provided
- Have `.id("quick-capture")` for scroll anchoring
- Use `.transition(.move(edge: .bottom).combined(with: .opacity))`
- Dismiss on tap-away (handled by parent via `onChange(of: isQuickCaptureFocused)`)

### Requirement: Per-day inline quick capture in upcoming view
The system SHALL allow the user to create a task inline within any day section or month sub-section of the Upcoming view. Tapping any existing "Add Reminder" CTA (dashed circle button, day header, empty day row, month day sub-section) SHALL activate an inline text field within that section. Committing the field SHALL create a task with that day's date. Only one inline field SHALL be active at a time across the entire view.

#### Scenario: Tapping Add Reminder activates inline field for that day
- **WHEN** the user taps the "Add Reminder" button at the bottom of a day section
- **THEN** an inline text field appears within that section
- **AND** no other inline field is visible in any other section
- **AND** the text field is focused

#### Scenario: Tapping a day header activates inline field for that day
- **WHEN** the user taps a day section header in the upcoming view
- **THEN** an inline text field appears within that section
- **AND** the field is pre-configured for that day's date

#### Scenario: Tapping an empty day row activates inline field
- **WHEN** the user taps an empty day row in the upcoming view
- **THEN** an inline text field appears for that day

#### Scenario: Tapping a month sub-section day activates inline field
- **WHEN** the user taps a day activation target within a month sub-section
- **THEN** an inline text field appears for that day within the sub-section

#### Scenario: Committing inline field creates task with day's date
- **WHEN** the user types text in the inline field and presses return
- **THEN** a new task is created with that text
- **AND** the task's `dueDate` is set to that day's date
- **AND** the inline field clears and remains focused for rapid entry
- **AND** the keyboard stays visible for continued input

#### Scenario: Chevron opens full editor with date pre-filled
- **WHEN** the user taps the chevron button on the inline field
- **THEN** the full ReminderEditorView opens as a sheet
- **AND** the `initialDate` is set to that day's date
- **AND** the inline field closes

#### Scenario: Tapping a different section's CTA moves the inline field
- **WHEN** the user has an inline field active in one day section
- **AND** taps the "Add Reminder" button in a different day section
- **THEN** the inline field closes in the original section
- **AND** opens in the newly tapped section
- **AND** any typed text in the original field is discarded

#### Scenario: Swipe-to-cancel dismisses the inline field
- **WHEN** the user swipes to cancel on the active inline field
- **THEN** the inline field is dismissed
- **AND** the "Add Reminder" button reappears
- **AND** any typed text is discarded
