## Context

`TaskRowView` renders a flat context menu (Today / Tomorrow / Next Week / Later / Schedule / Move to Top/Bottom / Move to List / Delete). "Later" clears the due date (`rescheduleToLater`) but is misread as a temporal target and collides with the "Later" tab. Specific date/time entry requires the generic "Schedule" sheet, which opens collapsed (`expandedPicker = initialDueDate != nil ? .date : nil`). Subtask rows exist only in the editor's subtask section and wire zero context-menu callbacks. Since commit `72f901d`, dated subtasks no longer surface in segment views even though `task-subtasks` spec requires it.

Both `TimelineViewModel` (`ReminderSegmentViewModel`) and `ListDetailViewModel` carry parallel reschedule methods (`rescheduleTo*` + `bulkRescheduleTo*`). The compact schedule sheet lives in `Editor/DatePickerSheet.swift` backed by `TaskScheduleDatePickerViewModel`.

## Goals / Non-Goals

**Goals:**
- One learnable, unified set of due-date actions on task rows and subtask rows: flat Today / Tomorrow / This Weekend, "No Date", a "More" submenu (Next Week / Next Month / Custom…) — with state-aware hiding.
- Replace the ambiguous "Later" label with "No Date".
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

### 1. Flat presets + "More" submenu replaces the flat scheduling items

`TaskRowView`'s context menu lists Today / Tomorrow / This Weekend flat, then "No Date" (when the task has a date), and puts Next Week / Next Month / Custom… inside `Menu("More")`. Rationale: the frequent presets stay single-tap, the long tail hides one level, and "No Date" resolves the "Later" ambiguity without a two-level nest that leaves the top menu looking sparse. Alternatives considered: full "Due Date ▸" group (rejected — every action costs a second tap and the top level reads as just two submenus); rename-only "No Date" placement below "More" (rejected — it reads as an afterthought instead of a first-class date option).

### 1b. Menu is state-aware and context-aware

- The preset whose target equals the task's current due date is omitted (e.g. "Today" for a task due today, "Tomorrow" for a task due tomorrow), so the menu leads with the action that changes the date. Undated and overdue tasks show every preset.
- "No Date" appears only when the task has a due date, positioned above "More" as a first-class date option (Apple Reminders naming).
- "Move to List" omits the task's current list for root tasks (no-op target); subtask menus keep every list because choosing the parent's list = promote-in-place.
- Reorder actions are place-aware via closure wiring: time tabs pass none (time-sorted), list detail passes Move to Top/Bottom (gated on >1 sibling), editor subtasks pass Move Up/Down (gated on sibling existence).

### 2. `TaskRowView` takes a single `onDueDateAction: (DueDateAction) -> Void` callback

Replace `onMoveToToday / onMoveToTomorrow / onMoveToNextWeek / onMoveToLater / onSchedule` with one enum-based callback:

```swift
enum DueDateAction {
    case none, today, tomorrow, thisWeekend, nextWeek, nextMonth, custom
}
```

The menu always shows every item (no per-item hiding). This drops the `canMoveToToday/Tomorrow/NextWeek` gating from the menu path entirely — presets are no-ops at worst, and predictable (Apple/Things behave this way). `.custom` is view-level (opens the sheet); the rest map to VM reschedule calls. `TaskNodeView` (dead code, only consumer of the old callbacks) is deleted.

### 3. Preset date math lives as statics on `ReminderSegmentViewModel`

`DetailViewModel` already calls `ReminderSegmentViewModel.nextMonday(from:)`. Add siblings:

- `nextSaturday(from:)` — today if already Sat/Sun, else the next Saturday. "This Weekend" = Saturday.
- `nextMonth(from:)` — `startOfDay + 1 month`, clamped to the last day of that month when the day-of-month overflows (e.g. Jan 31 → Feb 28/29).

Both ViewModels get `rescheduleToThisWeekend`, `rescheduleToNextMonth`, `rescheduleToNone` (renamed from `rescheduleToLater`) plus bulk variants. `scheduleTask` remains the Custom path.

### 4. Schedule sheet gains initial focus

`TaskScheduleDatePickerViewModel` takes `initialFocus: ExpandedPicker?` in init; the sheet propagates it. "Custom…" passes `.date` when the task has no date, else `.time`. This replaces the current `initialDueDate != nil ? .date : nil` heuristic.

### 5. Bulk: mirror presets + implement "Pick a Date…"

`BulkActionsToolbar`'s Date menu becomes Today / Tomorrow / This Weekend / Next Week / Next Month / Pick a Date… / None (`onRescheduleLater` → `onRescheduleNone`). "Pick a Date…" (currently a dead `onRescheduleCustom` stub in both views) presents a reused `TaskScheduleDatePickerSheet` bound to a `BulkScheduleConfig { taskIDs }`, committing through a new `bulkRescheduleToDate(taskIDs:dueDate:hasTime:)` in both ViewModels (loops `scheduleTask` logic over the set).

### 6. Subtask context menu in the editor

`EditorView`'s subtask `TaskRowView` wires: `onDueDateAction` (same enum), `onMoveToList` (sections from the editor's `reminderLists` `@Query` via `buildListSections`), new `onMoveUp`/`onMoveDown` (sibling reorder by swapping `sortOrder` with the adjacent sibling), and `onDelete`. `showsDueDate: true` so assigned date/time renders in the metadata line. `ReminderEditorViewModel` gains the reschedule/schedule/move/reorder methods; the editor presents the schedule sheet through a `@State` config. "Move to List" sets `parentTask = nil` and reassigns `sortOrder` in the destination (un-nest → root); picking the parent's own list = promote-in-place.

### 7. Dated subtasks resurface in segment views

`TimelineViewModel`'s segment filters (today/tomorrow/upcoming/overdue) change from "roots only" to "roots OR subtask with a due date". Rendered flat at depth 0 (per spec — no indent/collapse). Undated subtasks remain editor-only. No dedup risk: parents render without their children under `72f901d`, so a surfaced subtask appears once, standalone. List detail stays roots-only.

### 8. Spec note updates

`app-mental-model` "Dead code" section reworded: the preserved "Later" label is replaced by the flat presets / "More" submenu with "No Date".

## Risks / Trade-offs

- **Always-visible presets** (dropping `canMoveTo*`) → "Today" on a task already due today is a visible no-op. Mitigation: acceptable, matches Apple/Things; presets are self-explanatory.
- **Resurfacing dated subtasks** reverses part of `72f901d` → users who hid subtasks see dated ones reappear in time tabs. Mitigation: only *dated* subtasks resurface (undated stay hidden); parent rows already show a subtask summary, and the existing `task-subtasks` spec mandates this behavior.
- **Bulk custom date** applies one date/time to all selected tasks → tasks with differing schedules are flattened. Mitigation: sheet defaults to today and shows the count context; uniform application is expected for bulk.
- **`TaskRowView` API change** touches TimelineView / DetailView / EditorView call sites → all updated in the same change; dead `TaskNodeView` deleted to avoid breaking the old API.
- **Same-day-of-month "Next Month"** clamps (Jan 31 → Feb 28) → user might expect Mar 3. Mitigation: clamp is the least-surprising calendar behavior; document in the preset tooltip/subtitle if needed.

## Migration Plan

Label- and behavior-only change; no SwiftData schema change, no data migration. Release together since menu labels ("Later" → "No Date", "Due Date ▸" group → flat presets + "More") are user-visible but non-destructive.

## Open Questions

- "This Weekend" = Saturday. If Friday-evening start is preferred, adjust `nextSaturday` to include Friday after a cutoff. Defaulting to Saturday.
- Future: time presets ("Later Today", "Evening") under the same Due Date group — deferred.
