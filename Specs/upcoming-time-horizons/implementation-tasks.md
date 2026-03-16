# TaskList Implementation Tasks (Upcoming Time Horizons)

## Status
- Scope source: `Specs/upcoming-time-horizons/prd.md`
- Design source: `Specs/upcoming-time-horizons/design-spec.md`
- Baseline source: `Specs/tasklist/prd.md`
- Last updated: 2026-03-11

## 1. Upcoming Filtering and Eligibility
- [x] Keep active-task filter (`isCompleted != true`).
- [x] Update `Upcoming` filtering to exclude tasks due today.
- [x] Update `Upcoming` filtering to exclude tasks due tomorrow.
- [x] Update `Upcoming` filtering to exclude overdue tasks.
- [x] Update `Upcoming` filtering to exclude unscheduled tasks (`dueDate == nil`) — these belong to `Someday`.

## 2. Time-Horizon Sectioning
- [x] Implement horizon grouping in `Upcoming` with fixed order:
  - [x] `This Week`
  - [x] `Next Week`
  - [x] `Later`
- [x] Ensure each task appears in exactly one section.
- [x] Classify using calendar-week boundaries based on user locale/calendar settings.

## 3. Section Visibility and Expansion
- [x] Render only non-empty sections.
- [x] Hide empty sections entirely (no section-level empty copy).
- [x] Apply default expansion only to rendered sections:
  - [x] `This Week` expanded
  - [x] `Next Week` collapsed
  - [x] `Later` collapsed
- [x] If all sections are empty, show one tab-level `Upcoming` empty state.

## 4. Sorting Rules in Upcoming
- [x] Sort `This Week`, `Next Week`, `Later` by:
  - [x] Due date ascending
  - [x] CreatedAt descending (tie-breaker)
- [x] Verify stable deterministic ordering for same-day tasks.

## 5. Upcoming Row Actions
- [x] Keep existing Upcoming row actions:
  - [x] `Today`
  - [x] `Tomorrow`
- [x] Add `Schedule` row action label.
- [x] `Schedule` opens date-picker sheet.
- [x] Picking a date immediately applies due date.
- [x] Picker sheet auto-dismisses after date selection.
- [x] Do not show `Save`/`Cancel` in schedule flow.
- [x] Do not include `Clear date` in schedule flow.

## 6. Existing Behavior Regression Checks
- [ ] Completion chip delay/cancel behavior still works.
- [ ] Swipe-to-delete still works and cancels pending completion.
- [ ] Task title link detection still works.
- [ ] Today/Tomorrow tab filtering remains unchanged.
- [ ] Capture bar behavior remains unchanged.

## 7. Accessibility and Localization
- [x] Section headers are readable and announced in correct visual order.
- [x] Collapsed/expanded state is exposed to VoiceOver.
- [x] Empty-state copy is readable by VoiceOver.
- [x] Horizon labels and empty-state text are localizable.
- [x] Week-boundary classification respects locale calendar settings.

## 8. QA Scenarios
- [ ] Task due later this week appears in `This Week` only.
- [ ] Task due in next calendar week appears in `Next Week` only.
- [ ] Task due beyond next week appears in `Later` only.
- [ ] Task with no due date appears in `Someday` only.
- [ ] Overdue task is not visible in `Upcoming`.
- [ ] No empty sections are displayed.
- [ ] If only one section has tasks, only that section is shown.
- [ ] If no sections have tasks, only tab-level empty state is shown.
- [ ] `Schedule` action: pick date -> task moves to correct section.
- [ ] `Today` action moves task out of `Upcoming` into `Today`.
- [ ] `Tomorrow` action moves task out of `Upcoming` into `Tomorrow`.
- [ ] Week rollover reclassifies tasks correctly (boundary check).

## 9. Documentation Updates
- [x] Update `README.md` if Upcoming behavior and sorting description changes.
- [x] Add post-implementation notes to `decisions.md` if UI behavior deviates from spec defaults. (Not required: implementation matches spec defaults.)
- [x] Keep PRD and design spec in sync with any implementation-time adjustments.
