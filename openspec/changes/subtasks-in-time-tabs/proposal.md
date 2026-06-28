## Why

Subtasks are currently invisible in time tabs (Today/Tomorrow/Upcoming). The original design (archived `add-nested-tasks`) deliberately left them flat — a subtask appears as a standalone row if it has its own due date, and is invisible if it doesn't. Users expect to see the parent-child hierarchy wherever they look at tasks, not just in list views.

## What Changes (from Original Design)

The original design in `archived/add-nested-tasks/design.md` Decision 2 stated:
> "Segment views show tasks independently regardless of nesting"

This decision is being revisited. The new goal: **render subtasks nested and expanded inline under their parent in time tabs**, matching the inline hierarchy already present in `ListDetailView`.

## Capability Changes

- **`task-subtasks`** (extended): Segment views now flatten and render hierarchy rather than showing flat rows
- **`task-row-display`** (extended): Need a shared tree-flattening utility used by both `ListDetailViewModel` and `ReminderSegmentViewModel`

## Status

**Exploration phase.** Decision on exact nesting approach (Apple-style vs Todoist-style) deferred pending further research into how each app handles subtasks across all time views.
