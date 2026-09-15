## MODIFIED Requirements

### Requirement: Capture bar presence is surface-aware

The capture bar SHALL be shown on every surface — the time segment roots (Today, Tomorrow, Upcoming), inside a selected list's task view, **and on the Lists overview (sidebar column)**. Exactly one `CaptureBarViewModel` instance SHALL back every visible bar, shared app-wide across all mounted bars.

#### Scenario: Capture bar on time segment roots

- **WHEN** the user is on the Today, Tomorrow, or Upcoming segment
- **THEN** the capture bar is visible at the bottom of the detail column
- **AND** captured tasks resolve their date from the selected segment (same as today)

#### Scenario: Capture bar inside a list's tasks

- **WHEN** the user has selected a list and is viewing its tasks
- **THEN** the capture bar is visible at the bottom of the detail column
- **AND** captured tasks are assigned to the selected list, undated

#### Scenario: Capture bar on the Lists overview

- **WHEN** the user is viewing the Lists overview (sidebar column)
- **THEN** the capture bar is visible at the bottom of the sidebar column
- **AND** captured tasks are assigned to the default Inbox list
- **AND** captured tasks have no `dueDate`

#### Scenario: One bar visible at a time on compact

- **WHEN** the app is running on a compact-width device (iPhone / iPad compatibility)
- **THEN** only one capture bar is visible at a time — the sidebar bar when the Lists overview is shown, or the detail bar when a segment or list is shown
- **AND** the two bars share the same `CaptureBarViewModel`, so in-flight draft text and focus state persist when switching between surfaces

---

## ADDED Requirements

### Requirement: Capture bar is backed by a single shared CaptureBarViewModel

The `MainTabView` SHALL own the single `CaptureBarViewModel` instance. That instance SHALL be the sole owner of the capture bar's minute-aligned refresh timer and the in-flight draft text. All mounted capture bars (sidebar and detail columns) SHALL render from this single shared instance.

#### Scenario: Draft text survives surface switch

- **WHEN** the user types text in the detail column's capture bar (e.g. on Today)
- **AND** reveals the sidebar
- **THEN** the sidebar capture bar shows the same in-flight text
- **AND** no commit occurs until the user explicitly submits

#### Scenario: Single timer across all surfaces

- **WHEN** the minute-aligned timer fires
- **THEN** the shared `CaptureBarViewModel.now` property updates once
- **AND** the date displayed on Upcoming-segment target chips (and the overview Inbox default) reflects the new value

### Requirement: Overview capture targets Inbox undated

When capturing on the Lists overview, the capture bar's default target SHALL be the default Inbox list (`ReminderDefaults.defaultListName`) with no `dueDate` (undated).

#### Scenario: Capture on overview creates undated Inbox task

- **WHEN** the user types a task title on the Lists overview bar and submits
- **THEN** a new `TaskItem` is created with `reminderList` set to the default Inbox list
- **AND** `dueDate` is `nil`

#### Scenario: Default Inbox list is created if missing

- **WHEN** the user captures a task on the overview and no Inbox list exists yet
- **THEN** the default Inbox list is created automatically
- **AND** the captured task is assigned to it

---

## MODIFIED Requirements

### Requirement: Capture target resolves from the selected surface

The capture bar's default target SHALL resolve from the active surface: the selected time segment's date on time segment roots, the selected list (undated) when viewing a list's tasks, **or the Inbox list (undated) when viewing the Lists overview**.

#### Scenario: Capture on a time segment assigns the segment date

- **WHEN** the user captures a task on the Today segment
- **THEN** the task is created with `dueDate = start of today`
- **AND** the task is assigned to the default Inbox list

#### Scenario: Capture in a list assigns to that list

- **WHEN** the user captures a task while viewing a specific list's tasks
- **THEN** the task is created with no `dueDate`
- **AND** the task is assigned to the viewed list

#### Scenario: Capture on the overview assigns to Inbox

- **WHEN** the user captures a task on the Lists overview
- **THEN** the task is created with no `dueDate`
- **AND** the task is assigned to the default Inbox list
