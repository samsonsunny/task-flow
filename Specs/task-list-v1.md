# Task List v1 (Iteration 1)

## Status
- Locked for iteration 1 implementation.

## Scope
- The task list is a primary working surface in iteration 1.
- No detail view is required for core list usage.

## Row Contract
- Row content: task title only.
- Title layout: `1...3` lines, tail truncation after line 3.
- URL behavior: detect `http`/`https` links in title text and render link segments tappable.
- Visual hierarchy: calm flat row styling using semantic tokens.
- Minimum tap target: 44pt.

## Ordering
- Sort order is newest first (`createdAt` descending).
- Ordering is stable for day-to-day use and easy to reason about.
- Future smart ordering is tracked separately in `task-list-smart-order.md`.

## List Interactions
- Scrolling is allowed while typing in capture.
- Keyboard dismisses interactively on list scroll.
- Draft text remains preserved when keyboard dismisses.
- Trailing swipe delete is available on each row.

## States
- Empty state: minimal message with capture-first flow.
- Populated state: flat stream of tasks.
- No badges or extra metadata in rows for iteration 1 (URLs remain inline within title text).

## Accessibility
- Dynamic Type support for multiline titles.
- VoiceOver should expose clear task row labels and delete action.
- Color is not the sole signal for state.
