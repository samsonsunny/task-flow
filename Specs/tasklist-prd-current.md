# TaskList View PRD (Code-Mapped Baseline)

## Document Control
- Product: TaskFlow iOS
- Feature: TaskList View
- Status: Active
- Last updated: 2026-03-02

## 1. Purpose
Define the current TaskList behavior exactly as implemented, so future changes can be requested by updating this PRD first, then applying code updates against it.

## 2. Product Scope
The TaskList view is the app's primary and only working screen at launch. It supports:
- Viewing active tasks in date buckets (`Today`, `Tomorrow`, `Upcoming`)
- Adding tasks via global navigation `+` with on-demand capture bar
- Completing tasks via delayed completion chip
- Deleting tasks via trailing swipe action

Not in current scope:
- Task detail screen
- Due-date editing in TaskList
- Overdue-specific workflow/rollover policy beyond tab filtering
- Reminders/notifications
- Completed-task history screen
- Cloud sync/collaboration

## 3. Users and Primary Jobs
- Capture quickly: add tasks with minimal friction.
- Plan today: focus on current-day tasks only.
- Plan next day: stage tomorrow tasks in advance.
- Scan active work: review incomplete tasks by bucket instead of one long list.
- Clear tasks fast: complete or delete tasks inline.

## 4. Functional Requirements (Current Behavior)

### TL-01 Screen Entry and Navigation
- App opens directly into TaskList view.
- Navigation title is tab-contextual:
  - `Today` tab title: `Today`
  - `Tomorrow` tab title: `Tomorrow`
  - `Upcoming` tab title: `Tasks`
- Navigation bar includes a global trailing `+` action for task capture.
- TaskList uses a bottom tab bar with 3 tabs: `Today`, `Tomorrow`, `Upcoming`.
- Each tab item uses icon + text:
  - `Today`: `sun.max`
  - `Tomorrow`: `calendar`
  - `Upcoming`: `tray.full`
- `Today` and `Tomorrow` show subtitle dates in `EEE, MMM d` format (localized), e.g. `Thu, Feb 26`.

### TL-02 Data Source and Filtering
- Data uses SwiftData `@Query` on `TaskItem`.
- List includes only active tasks (`isCompleted != true`).
- Completed tasks are excluded from the main list.
- Tab filtering:
  - `Today`: tasks with due date on current calendar day only.
  - `Tomorrow`: tasks with due date on next calendar day only.
  - `Upcoming`: tasks not in `Today` or `Tomorrow` (no due date, future-dated beyond tomorrow, and overdue).

### TL-03 Ordering
- Sort order remains `createdAt` descending (newest first) within each tab.

### TL-04 Empty State
- No empty-state message is shown for empty tabs.

### TL-05 Row UI Contract
- Row contains:
  - Completion chip/button (44x44 tap area)
  - Task title text (max 3 lines)
- Title auto-detects `http`/`https` links and makes them tappable.
- Row visual state changes when pending completion is active.

### TL-06 Task Creation (Capture Bar)
- Capture starts from global navigation `+`.
- Tapping `+` shows existing capture bar above keyboard with smooth animated transition.
- Capture bar is hidden by default (not always visible).
- No new capture-specific buttons are added.
- Placeholder text: `What's on your mind?`
- Text field supports 1...4 lines.
- Submit via keyboard Done / submit event.
- Trailing newline also triggers submit.
- Input normalization before save:
  - Trim whitespace/newlines
  - Replace embedded newlines with spaces
- Empty/whitespace-only input is rejected.
- On successful create, due date is assigned from active tab:
  - In `Today`, due date auto-assigns to today.
  - In `Tomorrow`, due date auto-assigns to tomorrow.
  - In `Upcoming`, keep current behavior (no auto due date assignment).
- Create path:
  - Create `TaskItem(taskTitle: normalizedTitle)` and set due date per tab rule above.
  - Insert into SwiftData context
  - Clear input
  - Keep focus active
- Dismiss/hide behavior:
  - Interactive scroll or tap outside hides the capture bar.
  - Hide occurs even if there is unsent input.
  - Unsent input is preserved as draft.
  - Reopening capture via `+` restores the draft.

### TL-07 Completion Flow (Delayed Finalization)
- Tapping completion chip sets temporary visual-complete state immediately.
- Final completion happens after 1.8 seconds.
- During pending window, second tap cancels completion.
- On finalize:
  - `isCompleted = true`
  - `completionDate = Date()`
- Completed item disappears from active list due to TL-02 filter.

### TL-08 Delete Flow
- Trailing swipe action exposes Delete.
- Full swipe allowed.
- Deletion cancels pending completion timer (if any) before deleting model.

### TL-12 Context Menu Rescheduling
- Each task row exposes a context menu for rescheduling. The options depend on the task's current view:
  - **Today tasks:**
    - `Tomorrow`: Sets due date to the next calendar day.
  - **Tomorrow tasks:**
    - `Today`: Sets due date to the current calendar day.
    - `Later`: Removes the due date (`dueDate = nil`), moving it to `Upcoming`.
  - **Upcoming tasks:**
    - `Today`: Sets due date to the current calendar day.
    - `Tomorrow`: Sets due date to the next calendar day.
- All due date changes use start-of-day normalization for date consistency.

### TL-09 Keyboard and Focus Behavior
- Keyboard dismisses interactively during scroll.
- Drag gesture marks scroll-before-typing signal for focus policy.
- Auto-focus runs on appear and app returning active.
- Focus policy conditions (via `CaptureFocusPolicy`):
  - Do not auto-focus if keyboard dismissed this session.
  - Do not auto-focus if user scrolled before typing.
  - Auto-focus when list is empty.
  - Auto-focus on quick return from background (<60s).
  - Auto-focus after long idle (>=30 min).
  - Auto-focus if previous session ended after prior task-added/focus events.

### TL-10 Accessibility
- Completion control has accessibility label/hint for complete vs revert behavior.

### TL-11 Launch Tab Selection Behavior
- On every cold app launch, default tab is time-based:
  - Before 8:00 PM local time: open `Today`.
  - At or after 8:00 PM local time: open `Tomorrow`.
- Within an active session (warm resume/relaunch), restore the last-opened tab for continuity.
- Time-based daily launch rule takes precedence for cold launches.

## 5. Data Model Requirements (TaskList-Relevant)
`TaskItem` fields currently used by TaskList:
- `taskId: String?` (stable key fallback for pending completion tracking)
- `taskTitle: String?`
- `isCompleted: Bool?`
- `completionDate: Date?`
- `createdAt: Date?`
- `dueDate: Date?` (tab filtering + capture auto-assignment)

Additional existing fields not surfaced in TaskList UI:
- `taskDescription: String?` (backward compatibility)

## 6. Visual and Design Constraints
- Screen background uses semantic `appBackground` token.
- Global `+` and capture bar use a liquid-glass style aligned with the tab bar visual language.
- Use native material-backed styling and semantic colors that adapt to both light and dark mode.
- Capture input uses glass-compatible surface/border tokens with rounded corners.
- No row separators.
- List style is plain.

## 7. Explicit Non-Requirements (As of Current Build)
- No due-date display in rows.
- No reminder setup.
- No completed-task browsing UI.
- No task detail navigation.
- No due-date edit flow in current TaskList version.
- No explicit empty-state text for empty tabs.
- No dedicated overdue handling experience beyond inclusion in `Upcoming`.
- No automated test coverage for TaskList behaviors in `TaskFlowTests` yet.

## 9. Acceptance Checklist for Future Changes
Before requesting AI code changes, update this PRD first:
1. Update requirement IDs impacted (`TL-xx`).
2. Add/modify acceptance criteria in plain language.
3. Mark any migration/data impact for `TaskItem` fields.
4. Update code-map references after implementation merge.
5. If behavior changed, update `README.md` to prevent drift.

## 10. Change Log
- 2026-02-25: Created initial code-mapped TaskList PRD baseline.
- 2026-02-26: Updated PRD for `Today`/`Tomorrow`/`Later` tab model, tab-scoped capture due-date defaults, tab filtering rules, and launch tab selection behavior.
- 2026-02-26: Updated PRD for global `+` capture entry, on-demand capture bar show/hide with draft restore, and liquid-glass visual requirements.
- 2026-02-27: Updated PRD to rename the `Later` tab to `Upcoming`, keeping filtering behavior and language consistent.
- 2026-03-02: Added `TL-12` context-menu rescheduling requirement for `Today`/`Tomorrow`, clarified due-date increment semantics, and removed duplicate requirement block.
- 2026-03-02: Updated `TL-12` to replace the "Move to Next Day" action with a comprehensive, tab-specific rescheduling context menu for `Today`, `Tomorrow`, and `Upcoming` views.
