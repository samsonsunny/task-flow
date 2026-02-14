# Task Capture Feature Spec

## Overview
This spec defines the core task capture experience for TaskFlow. The goal is to make capture zero-friction: open the app and immediately record a thought with minimal effort. The capture surface must be optimized for one-hand use, continuous entry in a single session, and smooth keyboard handling.

## Goals
- Zero-friction capture: user can start typing immediately on app open.
- One-hand friendly: primary controls within comfortable thumb reach.
- Continuous creation: rapid multi-task entry without repeated mode switches.
- Smooth keyboard handling: no jarring layout shifts or focus loss.
- Multiline title support: the title field grows vertically as needed.

## Non-Goals (for now)
- Due date selection UI
- Notes/description field
- Task priority
- Tagging
- Sync

## Core UX Decisions
- Primary pattern: Sticky bottom capture bar (always visible).
- Floating + button: removed.
- Quick-add sheet: removed.
- Title input: multiline, grows vertically up to a defined limit.
- Primary action: keyboard `Done` key (no inline Add button).
- Default flow: open app -> cursor ready -> type -> press Done -> task appears -> field clears -> keyboard stays open.

## Interaction Details
- Auto-focus the title input on first appearance.
- Do not steal focus again if the user dismisses the keyboard or scrolls.
- Pressing Return/Done creates a task using trimmed text; empty/whitespace-only entries are rejected.
- Return does not insert newline characters during entry; it submits.
- Newline characters from pasted input are normalized to spaces before save.
- After submit:
  - Clear the input.
  - Keep focus in the input to support rapid capture.
  - Do not dismiss the keyboard automatically.

## Keyboard Handling Best Practices
- Use interactive keyboard dismissal on scroll to feel natural.
- Avoid layout jumps when the keyboard appears; the bar should move with safe area / keyboard inset.
- In capture mode (keyboard visible), the capture bar should be flush to the keyboard with no vertical padding.

## Layout & Visuals
- Bottom bar is persistent and anchored to the safe area.
- Input is visually dominant with minimal chrome.
- No inline Add button is shown.
- Multiline input grows vertically (1 to N lines). N to be decided during implementation.
- Capture bar color mapping (locked):
  - Bar container uses `appBackground`.
  - Input surface uses `surface` with `border`.
  - Entered text uses `textPrimary`.
  - Placeholder text uses `textDisabled` (no opacity-based text coloring).
  - Any selected-row affordance uses `primaryAction` at 8-12% opacity.

## Future-Proof Extensions (Not in initial scope)
- Expandable drawer for optional fields (due date, notes, priority).
- Quick date chips (Today, Tomorrow, Next Week).
- Smart parsing (e.g., "Call John tomorrow 5pm" extracts date).
- Batch entry (one task per line).
- Optional Add & Close behavior.

## Open Questions
### Recommended Defaults (for decision)
- Max line count: 4 lines (locked).
- Keyboard after submit: keep open by default; only dismiss if the user explicitly hides it.
- Insertion feedback: subtle row animation (e.g., short fade/slide) to confirm creation without drawing focus.

## Implementation Notes
- No implementation should proceed until explicitly approved.
- Remove or disable any legacy quick-add UI when implementing the new bar.

## Pending Decisions (Recommendations)
### Sticky Bar Styling
- Recommended: Rounded card/pill style.\n- Rationale: visually separates capture from list, improves discoverability, and feels tactile without heavy chrome.

### Submission Trigger
- Locked: Keyboard `Done` key only (no inline Add button).\n- Rationale: removes an extra tap target and keeps capture in a single keyboard-driven flow.

### Auto-Focus Timing
- Recommended: Intelligent auto-focus.\n- Rationale: predicts capture intent while backing off when the user is browsing.

#### Intelligent Auto-Focus Rules (Decision)
- Summary checklist:\n  - Auto-focus on open if: list is empty OR task added in previous session OR quick return from background (<60s) OR input was focused last session.\n  - Do not auto-focus if: keyboard was dismissed in current session OR user scrolled before typing.\n  - Re-enable after long idle: 30 minutes.
- Auto-focus on app open if:\n  - The task list is empty, or\n  - The user added a task in the previous session (capture mindset).
- Do not auto-focus if:\n  - The user dismissed the keyboard in the current session, or\n  - The user scrolled the list before typing (browsing signal).
- Re-enable auto-focus next time if:\n  - The user added a task in the previous session, or\n  - The app was closed/backgrounded for a longer interval (locked: 30 minutes).
