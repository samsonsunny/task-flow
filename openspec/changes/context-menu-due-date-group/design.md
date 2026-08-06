## Context

`TaskRowView` renders a flat context menu (Today / Tomorrow / Next Week / Later / Schedule / Move to Top/Bottom / Move to List / Delete). "Later" clears the due date (`rescheduleToLater`) but is misread as a temporal target and collides with the "Later" tab. Specific date/time entry requires the generic "Schedule" sheet, which opens collapsed (`expandedPicker = initialDueDate != nil ? .date : nil`). Subtask rows exist only in the editor's subtask section and wire zero context-menu callbacks. Since commit `72f901d`, dated subtasks no longer surface in segment views even though `task-subtasks` spec requires it.

Both `TimelineViewModel` (`ReminderSegmentViewModel`) and `ListDetailViewModel` carry parallel reschedule methods (`rescheduleTo*` + `bulkRescheduleTo*`). The compact schedule sheet lives in `Editor/DatePickerSheet.swift` backed by `TaskScheduleDatePickerViewModel`.

## Goals / Non-Goals

**Goals:**
- One learnable, unified set of due-date actions on task rows and subtask rows: a "Deadline" submenu (None, divider, Today / Tomorrow / This Weekend / Next Week / Custom…) — with an active-item checkmark and calendar-day preset icons.
- Replace the ambiguous "Later" label with "None".
- "Custom…" opens the schedule sheet with the relevant picker pre-expanded.
- Subtask rows get a working context menu (promote / due date / sibling reorder / delete) and display their assigned date/time.
- Dated subtasks resurface as flat rows in segment views (restores `task-subtasks` spec compliance).
- Bulk Date menu mirrors the presets and "Pick a Date…" becomes functional.

**Non-Goals:**
- No time presets (e.g. "Later Today", "Evening") — future work.
- No changes to the editor's inline schedule form (`reminder-deadline-time` behavior unchanged).
- No drag-reorder in the editor's subtask list; reorder is via context menu only.
- List detail continues to show root tasks only (no subtree rendering).

## Decisions

### 1. Single "Deadline" submenu replaces the flat scheduling items

`TaskRowView`'s context menu puts every due-date action inside `Menu("Deadline")` — "None" first (always listed, no leading icon), a divider, then Today, Tomorrow, This Weekend, Next Week, Custom…. This mirrors Apple Reminders, which keeps the date actions in a "Deadline" menu reachable in two taps. Rationale: one discoverable, self-labeled group; "None" leads because it is the only action that removes the date rather than setting one, and the presets follow from the nearest target (Today) outward. There is no Next Month preset — any further-out date is a single pick in the Custom… sheet. Each preset row carries a leading calendar icon showing its target day-of-month (Today → today, Tomorrow → tomorrow, This Weekend → the upcoming Saturday, Next Week → the upcoming Monday); "None" and Custom… show no day number. Alternatives considered: flat Today / Tomorrow / This Weekend with the rest nested (rejected — the top level competed with the "Deadline" submenu and split a single concept); full "Due Date ▸" group (rejected — same shape, "Deadline" matches Apple's label); a generic "More" label (rejected — reads as a dumping ground rather than a deadline group).

### 1b. Menu is state-aware and context-aware

- The menu marks the action that matches the task's current due date with a leading checkmark: "None" when the task has no due date; the preset whose target day equals the due date (compared at `startOfDay`, time ignored); Custom… for any date matching no preset. Exactly one item is ticked at a time and no item is hidden — every action stays visible and reachable. Undated and overdue tasks show every preset.
- "None" is always listed first in the "Deadline" submenu, separated from the presets by a divider, so the date-clearing action is visually distinct from the date-setting presets.
- "Move to List" omits the task's current list for root tasks (no-op target); subtask menus keep every list because choosing the parent's list = promote-in-place.
- Reorder actions are place-aware via closure wiring: time tabs pass none (time-sorted), list detail passes Move to Top/Bottom (gated on >1 sibling), editor subtasks pass Move Up/Down (gated on sibling existence).

### 2. `TaskRowView` takes a single `onDueDateAction: (DueDateAction) -> Void` callback

Replace `onMoveToToday / onMoveToTomorrow / onMoveToNextWeek / onMoveToLater / onSchedule` with one enum-based callback:

```swift
enum DueDateAction {
    case none, today, tomorrow, thisWeekend, nextWeek, custom
}
```

The menu is state-aware (see 1b): the item matching the task's current due date is marked with a checkmark, and no item is hidden. This drops the `canMoveToToday/Tomorrow/NextWeek` gating from the menu path entirely. `.custom` is view-level (opens the sheet); the rest map to VM reschedule calls. `TaskNodeView` (dead code, only consumer of the old callbacks) is deleted.

### 3. Preset date math lives as statics on `ReminderSegmentViewModel`

`DetailViewModel` already calls `ReminderSegmentViewModel.nextMonday(from:)`. Add a sibling:

- `nextSaturday(from:)` — today if already Sat/Sun, else the next Saturday. "This Weekend" = Saturday.

Both ViewModels get `rescheduleToThisWeekend`, `rescheduleToNone` (renamed from `rescheduleToLater`) plus bulk variants. There is no "Next Month" preset anywhere — further-out dates are picked via the Custom… / "Pick a Date…" sheet. `scheduleTask` remains the Custom path.

### 4. Schedule sheet gains initial focus

`TaskScheduleDatePickerViewModel` takes `initialFocus: ExpandedPicker?` in init; the sheet propagates it. "Custom…" passes `.date` when the task has no date, else `.time`. This replaces the current `initialDueDate != nil ? .date : nil` heuristic.

### 5. Bulk: mirror presets + implement "Pick a Date…"

`BulkActionsToolbar`'s Date menu becomes Today / Tomorrow / This Weekend / Next Week / Pick a Date… / None (`onRescheduleLater` → `onRescheduleNone`). "Pick a Date…" (currently a dead `onRescheduleCustom` stub in both views) presents a reused `TaskScheduleDatePickerSheet` bound to a `BulkScheduleConfig { taskIDs }`, committing through a new `bulkRescheduleToDate(taskIDs:dueDate:hasTime:)` in both ViewModels (loops `scheduleTask` logic over the set).

### 6. Subtask context menu in the editor

`EditorView`'s subtask `TaskRowView` wires: `onDueDateAction` (same enum), `onMoveToList` (sections from the editor's `reminderLists` `@Query` via `buildListSections`), new `onMoveUp`/`onMoveDown` (sibling reorder by swapping `sortOrder` with the adjacent sibling), and `onDelete`. `showsDueDate: true` so assigned date/time renders in the metadata line. `ReminderEditorViewModel` gains the reschedule/schedule/move/reorder methods; the editor presents the schedule sheet through a `@State` config. "Move to List" sets `parentTask = nil` and reassigns `sortOrder` in the destination (un-nest → root); picking the parent's own list = promote-in-place.

### 7. Dated subtasks resurface in segment views

`TimelineViewModel`'s segment filters (today/tomorrow/upcoming/overdue) change from "roots only" to "roots OR subtask with a due date". Rendered flat at depth 0 (per spec — no indent/collapse). Undated subtasks remain editor-only. No dedup risk: parents render without their children under `72f901d`, so a surfaced subtask appears once, standalone. List detail stays roots-only.

### 8. Spec note updates

`app-mental-model` "Dead code" section reworded: the preserved "Later" label is replaced by the single "Deadline" submenu with "None" nested inside it after a divider, marked with an active-item checkmark, and the preset rows carrying calendar-day icons.

## Risks / Trade-offs

- **Always-visible presets** (dropping `canMoveTo*`) → "Today" on a task already due today is a visible no-op. Mitigation: acceptable, matches Apple/Things; presets are self-explanatory.
- **Resurfacing dated subtasks** reverses part of `72f901d` → users who hid subtasks see dated ones reappear in time tabs. Mitigation: only *dated* subtasks resurface (undated stay hidden); parent rows already show a subtask summary, and the existing `task-subtasks` spec mandates this behavior.
- **Bulk custom date** applies one date/time to all selected tasks → tasks with differing schedules are flattened. Mitigation: sheet defaults to today and shows the count context; uniform application is expected for bulk.
- **`TaskRowView` API change** touches TimelineView / DetailView / EditorView call sites → all updated in the same change; dead `TaskNodeView` deleted to avoid breaking the old API.

## Migration Plan

Label- and behavior-only change; no SwiftData schema change, no data migration. Release together since menu labels ("Later" → "None", flat items + "More" → single "Deadline" submenu) are user-visible but non-destructive.

## Open Questions

- "This Weekend" = Saturday. If Friday-evening start is preferred, adjust `nextSaturday` to include Friday after a cutoff. Defaulting to Saturday.
- Future: time presets ("Later Today", "Evening") under the same Due Date group — deferred.
