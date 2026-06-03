## Context

The Reminder Editor has separate toggles for Date and Time. Currently the Time toggle is disabled (`View.disabled(true)`) when no date is set (`draft.dueDate == nil`). This means a user must explicitly enable Date before they can enable Time, even though setting a time implicitly requires a date. The time row's drag gesture also gates on `draft.dueDate` being non-nil, preventing the time picker from being activated independently.

The fix is to decouple the Time toggle from the Date toggle's enabled state. When Time is enabled without a Date, the Date is auto-set to a sensible default (today).

## Goals / Non-Goals

**Goals:**
- Time toggle is always interactive regardless of Date toggle state
- Enabling Time without a Date auto-sets the date to today
- Removing Time (toggling off) does NOT clear the Date or the date picker
- The time picker row highlight/expand works independently via `draft.hasTime`

**Non-Goals:**
- No changes to the Date toggle behavior
- No changes to data model (`ReminderDraft`, `TaskItem`)
- No changes to save logic

## Decisions

| Decision | Chosen Approach | Alternatives Considered |
|---|---|---|
| Remove `.disabled` on time Toggle | Simply delete `View.disabled(draft.dueDate == nil)` modifier | — |
| Auto-date value when enabling time without date | Keep existing `nearestRoundedHour()` — it sets today + a sensible rounded time | Using `startOfDay` would lose the time component (midnight) which is wrong for a time toggle |
| Guard in drag gesture `onChanged`/`onEnded` | Remove `draft.dueDate != nil` guard; keep `draft.hasTime` guard | — |
| Clearing date on time toggle off | Do NOT clear date when time is toggled off | Could reset date to nil, but that would be destructive if user wants date-only after trying time |

## Risks / Trade-offs

- [Low] User enables time, date auto-sets to today. If they wanted a different date, they can adjust it in the date picker. This is intuitive and matches behavior of most calendar/reminder apps.
- [None] No data loss risk — enabling time only writes a date if one doesn't already exist.
