# Completed Tasks — Next Actions (Future Enhancement)

Status: Proposed
Owner: TBD
Date: 2026-02-06

## Context
The Completed Tasks view already implies that items are done, so showing “Done” on each row is redundant.  
We now show completion metadata in the row (example: `Completed · Jan 5`), which is a better use of secondary space.

## Goal
Define clear, high-value next actions for completed tasks so the row provides meaningful utility beyond status.

## Candidate Next Actions
1. Reopen task
- Value: Undo mistakes or revive a task that becomes relevant again.

2. Duplicate / Reuse
- Value: One-tap recreation of recurring tasks or repeatable workflows.

3. Add reflection / note
- Value: Capture what worked, blockers, or lessons learned.

4. View completion context
- Value: Recall when it was completed and any related details.

5. Archive / Delete
- Value: Reduce clutter and keep the completed list focused.

## Recommendation (Default UX)
Primary action:
- Reopen

Secondary action:
- Duplicate (via context menu or swipe action)

## Open Questions
1. Should we show a quick action affordance in the row (e.g., trailing icon) or keep actions in context menu?
2. Should completion metadata be relative (e.g., “2d ago”) or absolute (e.g., “Jan 5”)?

