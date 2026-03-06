# TaskList Design Spec (Upcoming Time Horizons)

## Document Control
- Product: TaskFlow iOS
- Feature: Upcoming Tab Time Horizons
- Spec type: Design Specification
- Status: Draft
- Last updated: 2026-03-06
- PRD reference: `Specs/upcoming-time-horizons/prd.md`
- Baseline reference: `Specs/tasklist/prd.md`

## 1. Design Goal
Transform `Upcoming` into a calm future-planning view by replacing a mixed list with clear calendar-week sections that reduce cognitive load and improve scanning.

## 2. Information Architecture
- Screen: existing `TaskList` view.
- Tab model remains unchanged:
  - `Today`
  - `Tomorrow`
  - `Upcoming`
- This spec changes only the content structure inside `Upcoming`.

Upcoming section order is fixed:
1. `This Week`
2. `Next Week`
3. `Later`
4. `Unscheduled`

## 3. Content Rules for Upcoming
### 3.1 Inclusion
`Upcoming` shows active tasks (`isCompleted != true`) that are:
- Not due today
- Not due tomorrow
- Not overdue

### 3.2 Exclusion
`Upcoming` excludes:
- Tasks due today
- Tasks due tomorrow
- Overdue tasks
- Completed tasks

### 3.3 Section Assignment
- `This Week`: due date after tomorrow and within current calendar week.
- `Next Week`: due date in next calendar week.
- `Later`: due date after next calendar week.
- `Unscheduled`: no due date.

A task must appear in exactly one section.

## 4. Layout and Visual Contract
- Reuse existing TaskList visual language, spacing tokens, and row UI.
- Render section headers in list order defined above.
- Render only non-empty sections.
- Do not render placeholder rows for empty sections.
- If all sections are empty, show one tab-level empty state for `Upcoming`.

No new card style, chips, badges, or additional row metadata are introduced in this iteration.

## 5. Expansion and Disclosure Behavior
Default on opening `Upcoming`:
- `This Week`: expanded when present.
- `Next Week`: collapsed when present.
- `Later`: collapsed when present.
- `Unscheduled`: collapsed when present.

Precedence:
- Expansion defaults apply only to rendered (non-empty) sections.
- If a section is not rendered, no expansion state is kept for it.

## 6. Sorting and Ordering
Inside each section:
- `This Week`, `Next Week`, `Later`:
  - Primary: due date ascending
  - Secondary: createdAt descending
- `Unscheduled`:
  - createdAt descending

Section ordering never changes based on counts.

## 7. Interaction Design
### 7.1 Row Actions in Upcoming
Keep planning actions available from each upcoming row:
- Move to `Today`
- Move to `Tomorrow`
- Schedule

`Schedule` interaction:
- Selecting `Schedule` opens a date-picker sheet.
- Picking a date immediately updates the task due date.
- The picker sheet dismisses automatically right after date selection.
- No `Save`/`Cancel` confirmation controls.
- No `Clear date` action.

### 7.2 Automatic Progression
Section membership updates automatically as time advances and due dates cross boundaries.
No explicit migration UI is shown.

## 8. Empty States and Copy
- Section-level empty states are not shown because empty sections are hidden.
- If all sections are empty, show one calm tab-level empty state.

Proposed copy:
- Title: `Nothing in Upcoming`
- Body: `Future tasks will appear here when you schedule them.`

## 9. Accessibility
- Section headers must be announced clearly in visual order.
- Collapsed/expanded state must be exposed to VoiceOver.
- Task rows keep existing accessibility behavior.
- Empty-state copy should be fully readable and localized.

## 10. Edge Cases and Boundary Behavior
- Week boundaries follow user locale/calendar settings.
- Tasks due at day boundaries are interpreted by calendar-day semantics.
- A task with `dueDate == nil` always maps to `Unscheduled`.
- Overdue tasks remain hidden from `Upcoming` even when all sections are empty.

## 11. Out of Scope (This Iteration)
- Dedicated overdue replacement experience.
- Changes to `Today` or `Tomorrow` tab content rules.
- New visual indicators for urgency or workload.
- Drag-and-drop rescheduling.
- Calendar integration.

## 12. Design-Level Acceptance Criteria
1. Upcoming renders horizon sections in fixed order: `This Week`, `Next Week`, `Later`, `Unscheduled`.
2. Only non-empty sections are shown.
3. Overdue tasks are not visible in Upcoming.
4. Each visible task belongs to exactly one section.
5. Default section expansion behavior matches this spec and applies only to visible sections.
6. Sorting is deterministic and follows the section-specific rules.
7. When no section has tasks, one tab-level empty state is shown.
8. VoiceOver can identify section headers and disclosure state.

## 13. Implementation Notes for Design Handoff
- Preserve existing TaskFlow design tokens and list row style.
- Avoid introducing new color semantics for this feature.
- Keep animation subtle and consistent with current list transitions.
- If engineering constraints require deviating from collapsed defaults, document the reason in `decisions.md`.

## 14. Change Log
- 2026-03-06: Created design spec for Upcoming time-horizon model aligned to PRD decisions (calendar-week grouping, overdue exclusion, conditional section rendering).
