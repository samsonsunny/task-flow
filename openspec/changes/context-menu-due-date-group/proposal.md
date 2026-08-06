## Why

The task context menu confuses users. The "Later" action (which clears the due date) collides with the "Later" tab name and reads as a temporal target among siblings that are all dates. There is also no easy path to pick a specific date or time — it is buried behind a generic "Schedule" item that opens a sheet with nothing pre-expanded. Subtask rows have no working context menu at all.

## What Changes

- Replace the flat `Today / Tomorrow / Next Week / Later / Schedule` items in `TaskRowView` with a single **"Deadline"** submenu (Apple Reminders approach — every date action is two taps): **"None"** (always listed, no leading icon), divider, Today / Tomorrow / This Weekend / Next Week / Custom…. No Next Month preset — anything further is picked via Custom….
- The menu is **state-aware** via an active-item checkmark: "None" is ticked when the task has no date, the preset whose target day matches the due date (time ignored), and Custom… for any other date; nothing is hidden. Each preset row shows a leading calendar icon with its target day-of-month. "Move to List" excludes the task's own list for root tasks.
- "None" replaces the "Later" label (same behavior: clears the due date). Rename applied in `BulkActionsToolbar` and the mental-model spec note.
- "Custom…" opens the schedule sheet with the relevant picker **auto-focused** (`initialFocus: .date` when no date, else `.time`), instead of opening collapsed.
- New presets: **This Weekend** (next Saturday). Single + bulk variants added to `TimelineViewModel` and `DetailViewModel`.
- Bulk toolbar Date menu mirrors the preset set, and the currently dead "Pick a Date…" (`onRescheduleCustom`) becomes a real bulk date-picker sheet.
- Subtask rows in the editor gain the full context menu: **Move to List ▸** (un-nests → root; picking the parent's list promotes), the same due date actions, **Move Up / Move Down** (sibling reorder), **Delete**.
- Subtask rows in the editor display their assigned date/time (`showsDueDate: true`).
- Dated subtasks resurface as flat rows in segment views (Today/Tomorrow/Upcoming) — restoring the existing `task-subtasks` spec requirement that commit `72f901d` regressed. Undated subtasks stay editor-only.
- **BREAKING** (label change, not data): context-menu action labels `Later` and `Schedule` are removed.

## Capabilities

### New Capabilities
- `task-due-date-menu`: Unified due-date actions on task rows — a single "Deadline" submenu (None, divider, Today / Tomorrow / This Weekend / Next Week / Custom…) — plus active-item checkmark state, calendar-day preset icons, current-list exclusion, and schedule-sheet auto-focus for Custom.
- `subtask-context-menu`: Full context menu on subtask rows in the editor — Move to List (promote/un-nest), the same due date actions, Move Up/Down, Delete — plus date/time display on subtask rows.

### Modified Capabilities
- `task-subtasks`: Segment views restore flat rendering of *dated* subtasks (spec compliance); editor subtask rows show assigned date/time.
- `task-actions`: Add Move Up / Move Down sibling-reorder actions for subtasks in the editor.
- `app-mental-model`: Update the "Dead code" note that preserves the "Later" label to describe the single "Deadline" submenu with "None" and the active-item checkmark.

## Impact

- **Views**: `TaskRowView` (menu restructure), `BulkActionsToolbar` (preset set + custom bulk), `TimelineView` / `DetailView` (bulk custom date-picker sheet), `EditorView` (subtask menu wiring, schedule sheet, `showsDueDate: true`).
- **ViewModels**: `TimelineViewModel`, `DetailViewModel` (new `rescheduleTo*` + bulk variants, `bulkRescheduleToDate`), `ReminderEditorViewModel` (subtask reschedule/move/reorder), `TaskScheduleDatePickerViewModel` (initial focus).
- **Models**: none. SwiftData schema unchanged.
- **Specs**: `openspec/specs/task-subtasks`, `task-actions`, `app-mental-model`.
