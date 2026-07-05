## ADDED Requirements

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

#### Scenario: Tapping away dismisses inline field
- **WHEN** the user taps outside the quick capture field after entering text
- **THEN** the text is committed as a new task if non-empty
- **AND** the inline field is dismissed

#### Scenario: Empty commit is ignored
- **WHEN** the user presses return on an empty inline field
- **THEN** no task is created
- **AND** the field remains visible

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

### Shared QuickCaptureRow component

The system SHALL use a shared `QuickCaptureRow` component (defined in `Views/Components/QuickCaptureRow.swift`) for all inline quick capture fields. The component SHALL:

- Accept `@Binding text`, `@FocusState.Binding isFocused`, `onSubmit` callback, and optional `dateHint`
- Render as a row with a filled circle and text field
- Show the date hint label below the field when provided
- Have `.id("quick-capture")` for scroll anchoring
- Use `.transition(.move(edge: .bottom).combined(with: .opacity))`
- Dismiss on tap-away (handled by parent via `onChange(of: isQuickCaptureFocused)`)
