# TaskList Implementation Tasks (Today/Tomorrow/Later)

## Status
- Scope source: `Specs/tasklist-prd-current.md`
- Design source: `Specs/tasklist-design-spec.md`
- Last updated: 2026-02-26

## 1. Tabbed TaskList Structure
- [ ] Add 3-tab UI container in TaskList screen with labels:
  - [ ] `Today`
  - [ ] `Tomorrow`
  - [ ] `Later`
- [ ] Keep text-first tab items (no icons).
- [ ] Add subtitle date for `Today` and `Tomorrow` in `EEE, MMM d` localized format.

## 2. Data Filtering by Tab
- [ ] Keep active-task filter (`isCompleted != true`) for all tabs.
- [ ] Implement `Today` filter: due date is current calendar day.
- [ ] Implement `Tomorrow` filter: due date is next calendar day.
- [ ] Implement `Later` filter: tasks not in `Today` or `Tomorrow`:
  - [ ] No due date
  - [ ] Due date after tomorrow
  - [ ] Overdue
- [ ] Keep existing sort order (`createdAt` descending) within each tab.

## 3. Capture Bar Behavior
- [ ] Ensure capture bar is visible in all tabs.
- [ ] Keep existing input normalization and submit behavior.
- [ ] Assign due date from active tab on create:
  - [ ] `Today` -> today due date
  - [ ] `Tomorrow` -> tomorrow due date
  - [ ] `Later` -> no auto due date
- [ ] Verify input/focus behavior remains unchanged after tab integration.

## 4. Launch Tab Logic
- [ ] Implement cold-launch default tab rule:
  - [ ] Before 8:00 PM local time -> open `Today`
  - [ ] At/after 8:00 PM local time -> open `Tomorrow`
- [ ] Persist last-opened tab while app is active.
- [ ] Implement warm resume/relaunch in same session -> restore last-opened tab.
- [ ] Ensure cold-launch time rule takes precedence over persisted tab.

## 5. Existing Behavior Regression Checks
- [ ] Completion chip delay/cancel behavior still works per row.
- [ ] Swipe-to-delete still cancels pending completion and deletes item.
- [ ] Link detection in task title still works.
- [ ] No empty-state message appears in empty tabs.

## 6. Accessibility and Localization
- [ ] Ensure tab labels are announced as visible text.
- [ ] Ensure subtitle date strings read correctly in VoiceOver.
- [ ] Ensure date subtitles use locale-aware formatting.

## 7. QA Scenarios
- [ ] Add task in `Today`; verify due date and placement.
- [ ] Add task in `Tomorrow`; verify due date and placement.
- [ ] Add task in `Later`; verify no due date and placement.
- [ ] Verify overdue tasks appear in `Later` and not `Today`.
- [ ] Verify future-dated (beyond tomorrow) tasks appear in `Later`.
- [ ] Cold launch before 8:00 PM opens `Today`.
- [ ] Cold launch at/after 8:00 PM opens `Tomorrow`.
- [ ] Warm resume returns to last-opened tab.

## 8. Documentation Updates
- [ ] Update `README.md` if user-visible behavior changed.
- [ ] Add implementation notes or code-map references after merge.

