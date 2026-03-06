# TaskList Implementation Tasks (Today/Tomorrow/Upcoming)

## Status
- Scope source: `Specs/tasklist/prd.md`
- Design source: `Specs/tasklist/design-spec.md`
- Last updated: 2026-02-26

## 1. Tabbed TaskList Structure
- [x] Add 3-tab UI container in TaskList screen with labels:
  - [x] `Today`
  - [x] `Tomorrow`
  - [x] `Upcoming`
- [x] Use bottom tab bar tab items with icon + text:
  - [x] `Today` + `sun.max`
  - [x] `Tomorrow` + `calendar`
  - [x] `Upcoming` + `tray.full`
- [x] Add localized subtitle date context for `Today` and `Tomorrow` in `EEE, MMM d` format.

## 2. Data Filtering by Tab
- [x] Keep active-task filter (`isCompleted != true`) for all tabs.
- [x] Implement `Today` filter: due date is current calendar day.
- [x] Implement `Tomorrow` filter: due date is next calendar day.
- [x] Implement `Upcoming` filter: tasks not in `Today` or `Tomorrow`:
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
  - [x] `Upcoming` -> no auto due date
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

## 5. Context Menu Rescheduling
- [ ] Add context menu to task rows in all tabs.
- [ ] Today tab: implement "Tomorrow" action.
- [ ] Tomorrow tab: implement "Today" action.
- [ ] Tomorrow tab: implement "Later" action (sets dueDate to nil).
- [ ] Upcoming tab: implement "Today" action.
- [ ] Upcoming tab: implement "Tomorrow" action.

## 6. Existing Behavior Regression Checks
- [ ] Completion chip delay/cancel behavior still works per row.
- [ ] Swipe-to-delete still cancels pending completion and deletes item.
- [ ] Link detection in task title still works.
- [x] No empty-state message appears in empty tabs.

## 7. Accessibility and Localization
- [x] Ensure tab labels are announced as visible text.
- [ ] Ensure subtitle date strings read correctly in VoiceOver.
- [x] Ensure date subtitles use locale-aware formatting.
- [x] Ensure global `+` has accessibility label (`Add Task`) and 44x44 target.

## 8. QA Scenarios
- [ ] Add task in `Today`; verify due date and placement.
- [ ] Add task in `Tomorrow`; verify due date and placement.
- [ ] Add task in `Upcoming`; verify no due date and placement.
- [ ] Verify overdue tasks appear in `Upcoming` and not `Today`.
- [ ] Verify future-dated (beyond tomorrow) tasks appear in `Upcoming`.
- [ ] Cold launch before 8:00 PM opens `Today`.
- [ ] Cold launch at/after 8:00 PM opens `Tomorrow`.
- [ ] Warm resume returns to last-opened tab.
- [ ] Tap `+` shows capture bar and keyboard smoothly.
- [ ] Scroll/tap-outside hides capture bar.
- [ ] Hide with unsent text and verify draft restores on next `+`.
- [ ] Verify repeated capture works without opening/closing glitches.
- [ ] Today tab: Verify "Tomorrow" context menu action works.
- [ ] Tomorrow tab: Verify "Today" context menu action works.
- [ ] Tomorrow tab: Verify "Later" context menu action works.
- [ ] Upcoming tab: Verify "Today" context menu action works.
- [ ] Upcoming tab: Verify "Tomorrow" context menu action works.

## 9. Documentation Updates
- [x] Update `README.md` if user-visible behavior changed.
- [ ] Add implementation notes or code-map references after merge.
- [x] Verify PRD/design docs reflect global `+` and non-persistent capture bar.
