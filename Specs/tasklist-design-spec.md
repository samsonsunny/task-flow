# TaskList Design Spec (Today/Tomorrow/Upcoming)

## Document Control
- Product: TaskFlow iOS
- Feature: TaskList View
- Spec type: Design Specification
- Status: Draft
- Last updated: 2026-02-26
- PRD reference: `Specs/tasklist-prd-current.md`

## 1. Design Goal
Reduce anxiety and decision fatigue by showing tasks in simple time buckets so users can focus on immediate work without scanning one long mixed list.

## 2. Information Architecture
- Single TaskList screen with 3 bottom tab bar items:
  - `Today`
  - `Tomorrow`
  - `Upcoming`
- Tab items use icon + text:
  - `Today` + `sun.max`
  - `Tomorrow` + `calendar`
  - `Upcoming` + `tray.full`
- Active context for `Today` and `Tomorrow` shows localized subtitle date in `EEE, MMM d` format (example: `Thu, Feb 26`).

## 3. Tab Content Rules
- `Today` tab: active tasks with due date on current day.
- `Tomorrow` tab: active tasks with due date on next day.
- `Upcoming` tab: active tasks not in `Today` or `Tomorrow`, including:
  - No due date
  - Due date after tomorrow
  - Overdue

Active means `isCompleted != true`.

## 4. Layout and Visual Contract
- Container: existing TaskList layout and visual tokens.
- Task list:
  - Plain list style
  - No row separators
  - Existing row design retained (completion chip + task title).
- Navigation trailing action:
  - Global `+` button in navigation bar.
  - Visual style follows Apple liquid-glass language and matches tab bar tone.
  - Uses adaptive material/semantic colors for light and dark mode.
- Capture bar:
  - Reuses existing capture component.
  - Hidden by default; shown on `+` tap.
  - Appears above keyboard with smooth show/hide animation.
  - Placeholder: `What's on your mind?`
  - Multiline input 1...4 lines
- Empty tabs:
  - No explicit empty-state message.

## 5. Interaction and Behavior
### 5.1 Capture Behavior by Tab
- Tap global `+` to show capture bar and focus input.
- Create from `Today`: auto-assign due date = today.
- Create from `Tomorrow`: auto-assign due date = tomorrow.
- Create from `Upcoming`: no auto due date assignment.
- Existing normalization/submit behavior remains unchanged.
- Continuous capture remains unchanged while visible:
  - submit creates task
  - input clears
  - focus stays active
- Hide behavior:
  - Interactive scroll/tap-outside hides capture bar.
  - Hide also applies when unsent text exists.
  - Unsent text is preserved and restored on next `+` tap.

### 5.2 Task Actions
- Keep existing in-list actions:
  - Delayed completion (1.8s, cancellable)
  - Swipe-to-delete
- No task detail flow in this phase.
- No due-date editing in this phase.

### 5.3 Launch Tab Selection
- On every cold app launch, apply time-based default:
  - Before 8:00 PM local time -> open `Today`
  - At/after 8:00 PM local time -> open `Tomorrow`
- In warm resume/relaunch during the same active session, restore last-opened tab for continuity.
- Cold-launch time rule has precedence over persisted-tab restoration.

## 6. Copy and Labels
- Tab labels:
  - `Today`
  - `Tomorrow`
  - `Upcoming`
- Navigation title by selected tab:
  - `Today` tab -> `Today`
  - `Tomorrow` tab -> `Tomorrow`
  - `Upcoming` tab -> `Tasks`
- No additional helper copy required for empty lists.

## 7. Accessibility
- Reuse existing accessibility labels/hints for completion control.
- Tab labels must be announced exactly as visible text.
- Date subtitles should be readable by VoiceOver as localized dates.

## 8. Out of Scope (This Iteration)
- Overdue-specific UX (separate overdue section or banner).
- Task detail screen.
- In-place due-date editing.
- Reminder/notification setup.
- Completed-task browsing.

## 9. Acceptance Criteria (Design-Level)
1. User can switch between `Today`, `Tomorrow`, and `Upcoming` tabs from TaskList.
2. `Today` and `Tomorrow` display date subtitle in `EEE, MMM d` localized format.
3. Each tab shows only tasks matching its defined content rule.
4. Global `+` shows capture bar with smooth keyboard-synced animation.
5. Capture bar hides on interactive scroll/tap-outside and restores unsent draft on reopen.
6. New task due date assignment matches active-tab rules.
7. Empty tabs render without empty-state text.
8. On cold launch, default tab follows the 8:00 PM time rule; warm in-session relaunch restores last-opened tab.
