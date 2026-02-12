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
- Primary action: visible Add button.
- Default flow: open app -> cursor ready -> type -> tap Add -> task appears -> field clears -> keyboard stays open.

## Interaction Details
- Auto-focus the title input on first appearance.
- Do not steal focus again if the user dismisses the keyboard or scrolls.
- Add button creates a task using trimmed text; empty/whitespace-only entries are rejected.
- After Add:
  - Clear the input.
  - Keep focus in the input to support rapid capture.
  - Do not dismiss the keyboard automatically.

## Keyboard Handling Best Practices
- Use interactive keyboard dismissal on scroll to feel natural.
- Avoid layout jumps when the keyboard appears; the bar should move with safe area / keyboard inset.
- Keep the capture bar visible above the keyboard and home indicator.
- Ensure the Add control remains reachable with the keyboard open.

## Accessibility & Usability
- Touch targets should be at least 44x44pt for tap accuracy.
- The Add button should be clearly labeled and accessible via VoiceOver.
- Ensure the input works with hardware keyboards and Full Keyboard Access.
- Avoid focus changes that surprise the user.

## Layout & Visuals
- Bottom bar is persistent and anchored to the safe area.
- Input is visually dominant with minimal chrome.
- Add button is high-contrast and immediately discoverable.
- Multiline input grows vertically (1 to N lines). N to be decided during implementation.

## Future-Proof Extensions (Not in initial scope)
- Expandable drawer for optional fields (due date, notes, priority).
- Quick date chips (Today, Tomorrow, Next Week).
- Smart parsing (e.g., "Call John tomorrow 5pm" extracts date).
- Batch entry (one task per line).
- Optional Add & Close behavior.

## Open Questions
### Recommended Defaults (for decision)
- Max line count: 4 lines (locked).
- Keyboard after Add: keep open by default; only dismiss if the user explicitly hides it.
- Insertion feedback: subtle row animation (e.g., short fade/slide) to confirm creation without drawing focus.

## Implementation Notes
- No implementation should proceed until explicitly approved.
- Remove or disable any legacy quick-add UI when implementing the new bar.

## Pending Decisions (Recommendations)
### Sticky Bar Styling
- Recommended: Rounded card/pill style.\n- Rationale: visually separates capture from list, improves discoverability, and feels tactile without heavy chrome.

### Add Button Style
- Recommended: Text label \"Add\".\n- Rationale: clearer intent than an icon-only action and better for accessibility.

### Auto-Focus Timing
- Recommended: Intelligent auto-focus.\n- Rationale: predicts capture intent while backing off when the user is browsing.

#### Intelligent Auto-Focus Rules (Decision)
- Summary checklist:\n  - Auto-focus on open if: list is empty OR task added in previous session OR quick return from background (<60s) OR input was focused last session.\n  - Do not auto-focus if: keyboard was dismissed in current session OR user scrolled before typing.\n  - Re-enable after long idle: 30 minutes.
- Auto-focus on app open if:\n  - The task list is empty, or\n  - The user added a task in the previous session (capture mindset).
- Do not auto-focus if:\n  - The user dismissed the keyboard in the current session, or\n  - The user scrolled the list before typing (browsing signal).
- Re-enable auto-focus next time if:\n  - The user added a task in the previous session, or\n  - The app was closed/backgrounded for a longer interval (locked: 30 minutes).
