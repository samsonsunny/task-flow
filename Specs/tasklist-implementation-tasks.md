# TaskList Implementation Tasks (Today/Tomorrow/Later)

## Status
- Scope source: `Specs/tasklist-prd-current.md`
- Design source: `Specs/tasklist-design-spec.md`
- Last updated: 2026-02-26

## 1. Tabbed TaskList Structure
- [x] Add 3-tab UI container in TaskList screen with labels:
  - [x] `Today`
  - [x] `Tomorrow`
  - [x] `Later`
- [x] Use bottom tab bar tab items with icon + text:
  - [x] `Today` + `sun.max`
  - [x] `Tomorrow` + `calendar`
  - [x] `Later` + `tray.full`
- [x] Add localized subtitle date context for `Today` and `Tomorrow` in `EEE, MMM d` format.

## 2. Data Filtering by Tab
- [x] Keep active-task filter (`isCompleted != true`) for all tabs.
- [x] Implement `Today` filter: due date is current calendar day.
- [x] Implement `Tomorrow` filter: due date is next calendar day.
- [x] Implement `Later` filter: tasks not in `Today` or `Tomorrow`:
  - [x] No due date
  - [x] Due date after tomorrow
  - [x] Overdue
- [x] Keep existing sort order (`createdAt` descending) within each tab.

## 3. Capture Bar Behavior
- [x] Add global navigation `+` action in TaskList.
- [x] Keep capture bar hidden by default.
- [x] Show capture bar on `+` tap with smooth bottom-up + fade animation.
- [x] Ensure keyboard and capture bar animation are synchronized.
- [x] Keep capture bar component/functionality unchanged once visible.
- [x] Keep existing input normalization and submit behavior.
- [x] Assign due date from active tab on create:
  - [x] `Today` -> today due date
  - [x] `Tomorrow` -> tomorrow due date
  - [x] `Later` -> no auto due date
- [x] Hide capture bar on interactive scroll/tap-outside.
- [x] Preserve unsent draft text on hide and restore on next `+` tap.
- [ ] Verify input/focus behavior remains unchanged after tab integration.

## 4. Launch Tab Logic
- [x] Implement cold-launch default tab rule:
  - [x] Before 8:00 PM local time -> open `Today`
  - [x] At/after 8:00 PM local time -> open `Tomorrow`
- [x] Persist last-opened tab while app is active.
- [x] Implement warm resume/relaunch in same session -> restore last-opened tab.
- [x] Ensure cold-launch time rule takes precedence over persisted tab.

## 5. Existing Behavior Regression Checks
- [ ] Completion chip delay/cancel behavior still works per row.
- [ ] Swipe-to-delete still cancels pending completion and deletes item.
- [ ] Link detection in task title still works.
- [x] No empty-state message appears in empty tabs.

## 6. Accessibility and Localization
- [x] Ensure tab labels are announced as visible text.
- [ ] Ensure subtitle date strings read correctly in VoiceOver.
- [x] Ensure date subtitles use locale-aware formatting.
- [x] Ensure global `+` has accessibility label (`Add Task`) and 44x44 target.

## 7. QA Scenarios
- [ ] Add task in `Today`; verify due date and placement.
- [ ] Add task in `Tomorrow`; verify due date and placement.
- [ ] Add task in `Later`; verify no due date and placement.
- [ ] Verify overdue tasks appear in `Later` and not `Today`.
- [ ] Verify future-dated (beyond tomorrow) tasks appear in `Later`.
- [ ] Cold launch before 8:00 PM opens `Today`.
- [ ] Cold launch at/after 8:00 PM opens `Tomorrow`.
- [ ] Warm resume returns to last-opened tab.
- [ ] Tap `+` shows capture bar and keyboard smoothly.
- [ ] Scroll/tap-outside hides capture bar.
- [ ] Hide with unsent text and verify draft restores on next `+`.
- [ ] Verify repeated capture works without opening/closing glitches.

## 8. Documentation Updates
- [x] Update `README.md` if user-visible behavior changed.
- [ ] Add implementation notes or code-map references after merge.
- [x] Verify PRD/design docs reflect global `+` and non-persistent capture bar.
