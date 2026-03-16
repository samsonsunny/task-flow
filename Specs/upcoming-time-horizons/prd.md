# TaskList Upcoming Time-Horizon PRD

## Document Control
- Product: TaskFlow iOS
- Feature: Upcoming Tab Time Horizons
- Status: Draft
- Last updated: 2026-03-11
- Companion baseline: `Specs/tasklist/prd.md`

## 1. Purpose
Define a focused PRD for restructuring only the `Upcoming` tab into calendar-based planning horizons so future tasks are easier to scan and less overwhelming.

## 2. Product Scope
This PRD applies only to the `Upcoming` tab.

In scope:
- Time-horizon sections for `Upcoming`
- Section eligibility and ordering rules
- Conditional section rendering and expansion behavior
- Updated sorting for tasks displayed in `Upcoming`

Out of scope:
- Any filtering or UX changes to `Today` and `Tomorrow`
- Completed-task behavior
- Dedicated overdue screen/flow
- Reminder/notification features

## 3. Users and Primary Jobs
- Review near-future commitments without scanning a long mixed list.
- Distinguish soon vs later work at a glance.
- Keep unscheduled tasks visible without mixing them into dated horizons (via `Someday`).

## 4. Functional Requirements (Upcoming Horizons)

### UH-01 Upcoming Eligibility
- `Upcoming` includes active tasks only (`isCompleted != true`).
- `Upcoming` excludes tasks due today.
- `Upcoming` excludes tasks due tomorrow.
- `Upcoming` excludes overdue tasks (due before today).
- `Upcoming` excludes unscheduled tasks (`dueDate == nil`) — these belong to `Someday`.

### UH-02 Section Model and Order
When tasks qualify, `Upcoming` is grouped into these sections in fixed top-to-bottom order:
1. `This Week`
2. `Next Week`
3. `Later`

### UH-03 Section Assignment Rules
Each eligible task appears in exactly one section:
- `This Week`: due date is after tomorrow and within the current calendar week.
- `Next Week`: due date is within the next calendar week.
- `Later`: due date is after next calendar week.

### UH-04 Calendar-Week Semantics
- Week boundaries use the user's locale/calendar settings.
- Horizon calculations are date-based and reevaluated from current time context.

### UH-05 Sorting Rules in Upcoming
- For `This Week`, `Next Week`, and `Later`:
  - Primary sort: due date ascending.
  - Secondary sort (tie-breaker): createdAt descending.

### UH-06 Conditional Section Rendering
- Only sections containing at least one task are shown.
- Empty sections are not rendered.

### UH-07 Expansion Behavior Precedence
Default expansion applies only to rendered (non-empty) sections:
- `This Week`: expanded when shown.
- `Next Week`: collapsed when shown.
- `Later`: collapsed when shown.

If no sections are rendered (no eligible tasks), show a single tab-level `Upcoming` empty state.

### UH-08 Task Actions in Upcoming
Upcoming rows support planning actions:
- Move to `Today`
- Move to `Tomorrow`
- Schedule

`Schedule` interaction contract:
- Tapping `Schedule` opens a date-picker sheet.
- Selecting a date immediately applies the new due date.
- After selection, the sheet dismisses automatically.
- No `Save`/`Cancel` confirmation step.
- No `Clear date` action in this flow.

### UH-09 Automatic Horizon Progression
- As dates change, tasks naturally move between horizons based on UH-03 rules.
- No manual user action is required for section transitions.

## 5. Data Model Requirements (Upcoming-Relevant)
Existing `TaskItem` fields used by this PRD:
- `isCompleted: Bool?`
- `dueDate: Date?`
- `createdAt: Date?`

No data model migration is required by this PRD alone.

## 6. UX and Content Requirements
- Upcoming should prioritize calm planning and low cognitive load.
- Section labels must be exactly:
  - `This Week`
  - `Next Week`
  - `Later`
- Empty-state copy is shown only when all sections are empty.

## 7. Explicit Non-Requirements (This PRD)
- No overdue tasks shown inside `Upcoming`.
- No requirement here to introduce an overdue replacement view.
- No changes to capture behavior in `Today`/`Tomorrow`/`Upcoming`.
- No changes to completion or deletion interaction patterns.

## 8. Acceptance Criteria
1. Overdue tasks do not appear in `Upcoming`.
2. Every task shown in `Upcoming` belongs to exactly one horizon section.
3. Only non-empty sections are rendered.
4. Expansion defaults are applied only to visible sections.
5. Dated sections sort by due date ascending, then createdAt descending.
6. Unscheduled tasks do not appear in `Upcoming` (they appear in `Someday`).
7. If all sections are empty, exactly one tab-level empty state is shown.
8. Week-boundary classification is correct for locale calendar settings.

## 9. Implementation Notes
- This PRD is additive and intended to coexist with `Specs/tasklist/prd.md`.
- If implementation changes baseline TaskList behavior, update both PRDs or consolidate into a single source of truth.

## 10. Change Log
- 2026-03-06: Created second PRD for `Upcoming` time-horizon model with conditional section rendering, overdue exclusion, and calendar-week grouping.
