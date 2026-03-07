# Task Capture PRD

## Document Control
- Product: TaskFlow iOS
- Feature: Task Capture
- Status: Active
- Last updated: 2026-03-07
- Companion baseline: `Specs/tasklist/prd.md`

## 1. Purpose
Define task-capture behavior as a standalone source of truth because capture is the core interaction loop of TaskFlow.

## 2. Product Scope
In scope:
- Capture entry affordance and visibility rules
- Capture bar input contract and submission behavior
- Input normalization and validation
- Tab-aware due-date assignment at create time
- Post-submit behavior for continuous capture
- Capture focus/session policy

Out of scope:
- Task list filtering/grouping
- Completion and deletion flows
- Upcoming horizon sectioning

## 3. Users and Primary Jobs
- Add tasks quickly with minimal friction.
- Stay in a continuous capture loop when entering multiple tasks.
- Avoid losing draft text when capture is dismissed.

## 4. Functional Requirements

### TC-01 Capture Entry
- Capture is initiated by the floating `+` button (`Add Task`) anchored bottom-trailing.
- The floating `+` button is shown only when the capture bar is hidden.

### TC-02 Capture Bar Visibility
- Capture bar is hidden by default.
- Tapping floating `+` toggles the capture bar:
  - If hidden: show capture bar and focus input.
  - If visible: hide capture bar.
- Capture bar dismisses when focus is lost (including keyboard dismissal during active use).
- Interactive drag/scroll actions dismiss capture.

### TC-03 Draft Persistence
- Dismissing capture does not clear unsent input.
- Reopening capture restores the current unsent draft.

### TC-04 Input and Submission
- Placeholder text is exactly: `What's on your mind?`
- Input supports multiline entry with a visual cap of `1...4` lines.
- Primary submit path is keyboard `Done` / submit event.
- If the user enters a trailing newline, capture submits immediately.
- Input normalization before create:
  - Replace embedded newlines with spaces.
  - Trim leading/trailing whitespace and newlines.
- Empty or whitespace-only input is rejected.

### TC-05 Task Creation Contract
- On valid submit, create `TaskItem(taskTitle: normalizedTitle, dueDate: dueDateForCreate(activeTab))`.
- Due-date assignment at create time is tab-aware:
  - `Today`: `dueDate = Date()`
  - `Tomorrow`: `dueDate = Date() + 1 day`
  - `Upcoming`: `dueDate = nil`
- Insert created task into SwiftData model context.

### TC-06 Continuous Capture After Submit
- After successful create:
  - Input is cleared.
  - Focus stays active.
  - Keyboard remains open.
  - Capture session records a task-added event.

### TC-07 Focus and Session Policy
- Session state tracks:
  - Keyboard dismissal in-session
  - Scroll-before-typing in-session
  - Typed-in-session
  - Last task-added/focused/backgrounded timestamps
- Auto-focus for visible capture follows `CaptureFocusPolicy`:
  - Do not auto-focus if keyboard was dismissed this session.
  - Do not auto-focus if user scrolled before typing.
  - Auto-focus when list is empty.
  - Auto-focus on quick app return (`< 60s`).
  - Auto-focus after long idle (`>= 30 min`).
  - Auto-focus if prior-session task-added/focus events indicate continuation.
- On return to active after long idle, session flags reset.

## 5. Data Model and Storage Requirements
- Task model fields used directly by capture:
  - `taskTitle: String?`
  - `dueDate: Date?`
- AppStorage keys used by capture session:
  - `capture_lastTaskAddedAt`
  - `capture_lastFocusedAt`
  - `capture_lastBackgroundedAt`

No model migration is required by this PRD alone.

## 6. UX and Visual Constraints
- Capture bar uses material-backed surface with semantic border/text tokens.
- Capture remains keyboard-first with no extra confirmation step.

## 7. Explicit Non-Requirements
- No inline `Add` button inside the capture bar.
- No separate capture sheet/modal.
- No date-picker during capture submit.
- No description field in capture.

## 8. Acceptance Criteria
1. User can open capture from floating `+` and start typing immediately.
2. Submitting with keyboard `Done` creates a task when normalized input is non-empty.
3. Trailing newline submission behavior matches keyboard submit behavior.
4. Input normalization guarantees single-line storage semantics (newlines become spaces).
5. Dismissing and reopening capture preserves unsent draft text.
6. After create, input clears and focus remains active for continuous capture.
7. Due date at create follows active-tab mapping (`Today`, `Tomorrow`, `Upcoming`).
8. Auto-focus behavior follows session policy and idle thresholds.

## 9. Implementation Notes
- Primary implementation lives in:
  - `TaskFlow/Views/Screens/TaskListView.swift`
  - `TaskFlow/Features/Capture/CaptureSessionState.swift`
  - `TaskFlow/Features/Capture/CaptureFocusPolicy.swift`
- If list-level behavior changes alongside capture, update this PRD and `Specs/tasklist/prd.md`.

## 10. Change Log
- 2026-03-07: Created standalone Task Capture PRD by extracting capture requirements from TaskList baseline and mapping them to current implementation.
