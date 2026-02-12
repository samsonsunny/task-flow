# Task Listing Visibility Options

## Context
When a new task is captured, it may not be visible immediately if the list is sorted by a field other than creation time. We need a UX pattern that confirms capture without forcing a heavy refactor.

## Options

### Option A: Toast + "View" Action (Minimal Refactor)
- What it does: After Add, show a small confirmation ("Task saved") with a "View" action that scrolls/jumps to the new task.
- Pros: Minimal list changes, preserves current sorting, clear confirmation.
- Cons: Requires user to tap "View" to see it.
- Refactor level: Low.

### Option B: "Just Added" Section (Moderate Refactor)
- What it does: Keep a temporary section at the top for the last 1-3 captured tasks; they fall back into the main list after a short time or on refresh.
- Pros: Immediate visibility while capturing; best for continuous capture sessions.
- Cons: Requires extra list structure and temporary state.
- Refactor level: Medium.

### Option C: Capture-First Sort (Larger Refactor)
- What it does: Always place newly created tasks at the top of the list on the capture screen.
- Pros: Guaranteed visibility, simplest mental model for capture.
- Cons: Conflicts with due-date or other sorts; changes core list behavior.
- Refactor level: High.

### Option D: Auto-Scroll to Inserted Task (Moderate to High)
- What it does: Programmatically scroll to the inserted task after Add.
- Pros: Preserves sorting and shows the item.
- Cons: Can feel jarring if the user is browsing; needs list IDs and scroll control.
- Refactor level: Medium to High.

## Recommendation
If we want minimal disruption now, Option A is the lightest-weight solution. If we want the strongest capture confirmation for continuous sessions, Option B is the best UX.

## Decision (Pending)
- Choose one option to finalize the capture confirmation behavior.
