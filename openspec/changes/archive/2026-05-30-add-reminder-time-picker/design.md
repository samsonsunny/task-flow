## Context

The reminder editor's schedule section currently renders a single row with a `"Due Date"` toggle and a compact inline `DatePicker` showing only date components. The `dueDate` field on `TaskItem` is a `Date?` — it naturally supports time, but the mapper currently strips time with `Calendar.current.startOfDay(for: $0)`.

The existing UI pattern uses a Form-based layout in SwiftUI. The new design extends this pattern with expandable inline pickers — a familiar iOS pattern (used by Calendar, Reminders, and system Settings).

## Goals / Non-Goals

**Goals:**
- Add an optional time picker for reminder due dates
- Implement expandable inline date and time rows that collapse after selection
- Auto-select nearest rounded hour when time is first enabled
- Remove time automatically when date is disabled
- Preserve time component in persistence
- Maintain backward compatibility with existing date-only reminders

**Non-Goals:**
- Add notification scheduling or alarms
- Change the reminder browsing or list display
- Schema migration or data model changes

## Decisions

### Decision: Use an optional enum for mutually exclusive expand/collapse
A single `@State` optional enum (`ExpandedPicker?` with cases `.date`, `.time`) tracks which picker is open. Tapping a row sets the value, causing the other picker to collapse automatically. On selection, the picker collapses by setting to nil. This enforces mutual exclusion at the type level.

Alternative considered: Two separate `@State` booleans. Rejected because it would require manual coordination to close one when the other opens, increasing bug surface.

### Decision: Store `hasTime` as a separate draft boolean
The draft will carry `hasTime: Bool`. When `hasTime` is true, `dueDate` includes time components. When false, time is stripped at save time. This keeps the draft model explicit about intent.

### Decision: Normalize `dueDate` to start of day when time is disabled
When `hasTime` is false, `ReminderDraftMapper` continues to apply `Calendar.current.startOfDay(for:)` to maintain backward compatibility with existing date-only reminders. When `hasTime` is true, the raw date with time is preserved.

Alternative considered: Always store full date with time. Rejected because existing date-only reminders would silently get a time (midnight), changing sort/filter behavior in segment views.

### Decision: Round time to nearest 30-minute interval on first enable
When the time toggle is first switched on, the time component defaults to the nearest future 30-minute boundary (e.g., 2:17 → 2:30, 2:45 → 3:00). This matches the system Reminders app behavior and avoids showing arbitrary minutes from the current clock time.

### Decision: Keep the time toggle disabled when no date is set
The time row will be visually disabled (grayed out, non-interactive) when `dueDate` is nil. Disabling the date toggle will automatically set `hasTime = false` and clear the time component.

### Decision: `initialDate` from caller turns on date toggle but not time
`ReminderEditorView` accepts an `initialDate: Date?` parameter, set by `ReminderSegmentDetailView` based on the active tab (Today→today, Tomorrow→tomorrow, Upcoming→day after tomorrow). When `initialDate` is non-nil, the date toggle turns on and the date is pre-selected, but the time toggle stays off by default. When `initialDate` is nil, the date toggle defaults to off. This keeps time opt-in even when a date is pre-filled from the tab context.

### Decision: Derive `hasTime` from existing `dueDate` on edit
When editing an existing reminder (`init(task:)`), `hasTime` is derived from whether `task.dueDate` has a non-midnight time component. If `dueDate` has hours/minutes that are not 00:00, `hasTime` is true and both toggles are on. If `dueDate` is nil or at midnight, `hasTime` is false and only the date toggle may be on if a date exists.

## Risks / Trade-offs

- [Existing date-only reminders get midnight time on edit] → The mapper preserves `startOfDay` normalization when `hasTime` is false. Editing an old reminder without toggling time on will keep it date-only.
- [Expanding a picker while one is already open could feel abrupt] → The collapse is animated and the user initiated the action by tapping, so it follows the expected iOS pattern of single-picker-at-a-time.
- [`hasTime` defaults differ between create and edit] → For create, `hasTime` starts false. For edit, `hasTime` is derived from whether the existing `dueDate` has a non-midnight time component.
