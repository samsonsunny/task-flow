Task Detail UX Refinements
==========================

Current focus:
------------
- Autosave indicator wired into `TaskDetailView`.
- Summary text for saved description is now visible in the description card.
- Notes autosave on exit to avoid data loss.

Next decision areas:
--------------------
1. Layout polish
 - Consider single focus card with minimal metadata.
 - Possibly hide reminder controls behind a disclosure or secondary sheet.
2. Interaction density
 - Replace large buttons with inline chips/pills (“Edit note”, “Add reminder”).
 - Explore stacked cards with peeking headers so content feels lighter.
3. Editing exposure
 - Option to move editing into transient sheet or overlay to keep detail view clean.
4. Typography/spacing
 - Reduce card shadows.
 - Lower opacity for secondary elements (due date, reminder text, saved note) to let title breathe.
5. Premium signal
 - Keep autosave indicator subtle. Maybe add “Saved 2s ago” timestamp for premium later.
 - Consider undo affordance or soft toast for premium users when changes commit.

What to do tomorrow
--------------------
- Compare card-stack vs. overlay edit sheet mockups, pick the simpler feel.
- Decide if completion/control chips should stay in header or move elsewhere.
- Evaluate if reminder switches can stay hidden until needed (ex: only after due date set).
- Confirm whether to keep autosave label or move it to toolbar/notification area.
- Plan next UX polish sprint once direction selected.
