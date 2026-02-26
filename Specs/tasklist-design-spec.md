# TaskList Design Spec (Today/Tomorrow/Later)

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
- Single TaskList screen with 3 top tabs:
  - `Today`
  - `Tomorrow`
  - `Later`
- Tab style is text-first (no icons in tab items).
- `Today` and `Tomorrow` show localized subtitle date in `EEE, MMM d` format (example: `Thu, Feb 26`).

## 3. Tab Content Rules
- `Today` tab: active tasks with due date on current day.
- `Tomorrow` tab: active tasks with due date on next day.
- `Later` tab: active tasks not in `Today` or `Tomorrow`, including:
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
- Bottom capture bar:
  - Present in all three tabs
  - Persistent with safe-area inset
  - Placeholder: `What's on your mind?`
  - Multiline input 1...4 lines
- Empty tabs:
  - No explicit empty-state message.

## 5. Interaction and Behavior
### 5.1 Capture Behavior by Tab
- Create from `Today`: auto-assign due date = today.
- Create from `Tomorrow`: auto-assign due date = tomorrow.
- Create from `Later`: no auto due date assignment.
- Existing normalization/submit behavior remains unchanged.

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
  - `Later`
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
1. User can switch between `Today`, `Tomorrow`, and `Later` tabs from TaskList.
2. `Today` and `Tomorrow` display date subtitle in `EEE, MMM d` localized format.
3. Each tab shows only tasks matching its defined content rule.
4. Capture bar is visible and usable in all tabs.
5. New task due date assignment matches active-tab rules.
6. Empty tabs render without empty-state text.
7. On cold launch, default tab follows the 8:00 PM time rule; warm in-session relaunch restores last-opened tab.
