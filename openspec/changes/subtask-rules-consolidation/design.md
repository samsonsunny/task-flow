## Context

Subtask behavior is defined in three places that disagree (base spec, stale `subtasks-in-time-tabs` change, shipped code). This change consolidates everything into one authoritative `task-subtasks` spec. The behavioral decisions below were made explicitly to settle the ambiguities; this file records why.

## Decisions

### D1. Parent completion cascades down; child completion never cascades up

Completing a parent completes all subtasks (completion date set, notifications cancelled); uncompleting reverses both. Completing all subtasks deliberately does **not** auto-complete the parent — the parent may represent a milestone with review/verification steps of its own, and silent auto-completion would remove the user's final say. This matches the original spec intent; only the implementation wiring is missing today.

### D2. Nesting depth capped at one level

A subtask cannot have children. Rationale: a single level keeps the mental model simple ("a task can be broken down once"), removes entire classes of UI problems (deep indentation, per-level collapse state, 16-level flattening edge cases), and covers the dominant real-world use case (project → steps). The data model stays a tree, so nothing prevents revisiting this later.

Enforcement must cover every mutation point: editor creation (the recursive editor sheet currently lets you open a subtask's editor and add depth-2 children) and drag-and-drop reparenting in list detail (dropping onto a row that already has a parent).

### D3. Legacy deep hierarchies are flattened by detaching below-depth-1 descendants to top level

Two options were considered for existing data that exceeds one level:

- **Re-parent grandchildren to their grandparent** (`Project > Phase > Step` → `Project > Phase` + `Project > Step`): preserves grouping under the root project but silently reshuffles structure mid-tree — tasks move between parents without user action.
- **Detach everything below depth 1 to independent top-level tasks** (chosen): the rule is trivial to state ("a subtask's children stop being nested"), there is no ambiguity about where a task lands — it becomes a normal task in the same list — and it reuses the exact promote-to-root semantics already shipped for Move-to-List and bulk move.

Detached tasks keep everything except the parent link: list membership, due date, priority, notes, tags, sort order (they slot among existing top-level tasks), completion state, and notifications. No notification is scheduled or cancelled by the detach itself. Flattening runs until no task-with-a-parent has a parent, and is idempotent afterwards.

Example: `Project > Phase > Step` becomes three separate tasks — Phase remains nested under Project; Step becomes an independent top-level task.

### D4. Delete cascades are specified as behavior, not mechanism

The requirement states the observable outcome (parent deleted ⇒ subtasks deleted, notifications cancelled, at every deletion site including bulk operations and time tabs). The implementation may use `.deleteRule(.cascade)` on the relationship or explicit recursive deletion before `modelContext.delete`; either satisfies the spec. Note for implementers: changing relationship delete rules touches the schema and should follow the AGENTS.md migration guidance.

### D5. Dated subtasks stay surfaced flat in time tabs

Confirmed current behavior (restored by commit `0549c0c`): a dated subtask qualifies for Today/Tomorrow/Upcoming/Overdue by its own due date and renders as a standalone flat row. Undated subtasks remain invisible outside the editor and list detail. Each task qualifies independently; there is no ancestor filter inheritance.

### D6. Docs-only scope

No code changes here. Known gaps between the new spec and the code are enumerated in the proposal so each can land as its own focused follow-up change. This change should be archived together with (or after) those follow-ups so the base spec does not become sanctioned drift.
