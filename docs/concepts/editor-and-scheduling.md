# Concept: Task Editor & Scheduling

**Feature:** Creating and editing tasks; picking due dates/times.
**Consolidated from (archived):** `mvvm-reminder-editor.json`, `mvvm-schedule-picker.json`

## Purpose

The editor is the full-screen authoring surface (create + edit) driven by a `Draft` value with a validated save pipeline. The date picker sheet is its scheduling sub-component, owning date/time toggles and picker expansion. Both share the half-hour rounding utility.

## Code map

| File | Role |
|---|---|
| `TaskFlow/Features/Editor/EditorView.swift` + `EditorViewModel.swift` | Editor screen |
| `TaskFlow/Features/Editor/Draft.swift` | `ReminderDraft` value type + mapper (save pipeline input) |
| `TaskFlow/Features/Editor/DatePickerSheet.swift` + `DatePickerViewModel.swift` | Schedule sheet |
| `TaskFlow/Features/Editor/ListPickerView.swift` | List assignment UI |
| `TaskFlow/Utilities/DateRounding.swift` | `nearestRoundedHour(from:)` — shared rounding |

## Responsibilities of EditorViewModel

### State
- `task` (nil = create mode), `draft`, `initialDraft`, computed `isDirty`, `isDiscardConfirmationPresented`.
- Receives `@Query` results (`reminderLists`, `reminderTags`) via init + `update(reminderLists:reminderTags:)`.

### Mutations
- **Save pipeline:** `save()` validates non-empty content → applies draft via `ReminderDraftMapper.apply()` → inserts new task if creating → assigns sort order → schedules notification when a time is set.
- **Close flow:** `handleClose()` shows discard confirmation only when dirty.
- **Subtask CRUD:** `addSubtask(title:to:)`, `deleteSubtask(_:)`, `toggleSubtaskCompletion(_:)` (notification-aware), `rescheduleSubtask(_:to:)`, `scheduleSubtask(_:dueDate:hasTime:)`, `moveSubtask(to:up:down:)` with boundary checks.

## Responsibilities of DatePickerViewModel

- Local state only: `dueDate`, time toggle, expanded-picker segment (`init(initialDueDate:initialFocus:)`).
- `toggleDate(isEnabled:)` — defaults a date when enabling.
- `toggleTime(isEnabled:)` — rounds to nearest half hour via shared `nearestRoundedHour(from:)`.
- Commit stays callback-based: parent receives `(dueDate, hasTime)` on Done. The VM owns state, not navigation.

## Invariants worth preserving

1. **The Draft is the single source of truth in the editor.** Never mutate the `TaskItem` directly from form controls; edits land on the draft, then apply through the mapper on save.
2. **Dirty tracking compares against `initialDraft`.** Any new editable field must be added to both the draft and the equality check, or discard protection silently breaks.
3. **Notifications schedule only when a specific time is set**; date-only tasks don't notify.
4. **Rounding lives in exactly one place.** `DateRounding.nearestRoundedHour` serves the editor *and* the picker — don't reintroduce private copies.
5. **UI-only state stays in views**: `@FocusState`, pressed-row effects, which picker segment is expanded visually.

## History

Originally two refactors (June–July 2026): ReminderEditorView (~424 lines → VM, keeping `ReminderDraft`/mapper interfaces untouched) and TaskScheduleDatePickerSheet (~182 lines → VM, plus deduplicating `nearestRoundedHour` into `Utilities/DateRounding.swift`). Subtask rescheduling/moving within the editor was added later.
