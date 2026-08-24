## Why

Subtask rules are scattered across three sources that contradict each other:

1. The base `task-subtasks` spec still mandates a nested tree UI (indentation, chevrons, collapse controls, a "3 ▸" counter) that no longer exists in the app.
2. The un-archived `subtasks-in-time-tabs` change describes inline nesting in time tabs that commit `72f901d` reverted — the folder was never cleaned up.
3. The shipped code implements different behavior (flat rows + "N/M" fraction, editor-only management) with dead cascade helpers (`completeDescendants()` is never called) and inconsistent delete handling (timeline deletions leak orphaned subtasks).

There is no single authoritative rule set, so every subtask change re-litigates the same questions and the spec/code gap grows.

## What Changes

This is a **docs-only** change: no code, schema, or test modifications.

- Rewrite `task-subtasks` as the single source of truth for subtask behavior, organized into data rules, lifecycle rules, per-surface display rules, interaction rules, and an explicit Limitations (non-goals) section.
- Lock in six behavioral decisions:
  1. Completing a parent **cascades down** to all subtasks (completion date set, notifications cancelled); uncompleting likewise reverses.
  2. Completing every subtask does **not** auto-complete the parent.
  3. Deleting a parent **cascade-deletes** its subtasks at every deletion site (editor, list detail single/bulk, time tabs single/bulk, Completed view).
  4. **Nesting depth is capped at one level** — a subtask can never have children; every mutation point enforces this.
  5. Dated subtasks surface as flat standalone rows in time tabs; undated subtasks appear only in the editor and list detail.
  6. Legacy hierarchies deeper than one level are **actively flattened**: descendants below depth 1 are detached into independent top-level tasks (keeping list, sort order, completion state, notifications).
- Remove the dead "List view displays nested tasks hierarchically" requirement; replace it with the shipped flat-display + fraction requirement.
- Update `app-mental-model` prose to drop the stale "inline expandable subtasks in time tabs" description.
- Delete the stale `subtasks-in-time-tabs` change folder outright (implemented, then reverted by `72f901d`, never archived).

## Capabilities

### Modified Capabilities
- `task-subtasks`: Full rewrite — one-level depth cap, completion/delete cascades, flat display with completed/total fraction, constrained drag-reparenting, legacy flattening, consolidated limitations.
- `app-mental-model`: Prose corrected — time tabs show dated subtasks flat; no inline expandable trees; parent rows show the fraction.

### New Capabilities
- None.

## Impact

- **Specs**: `openspec/specs/task-subtasks` (via delta, merged at archive), `openspec/specs/app-mental-model` (prose edited directly, matching the `context-menu-due-date-group` precedent for free-form docs).
- **Code**: none. This change intentionally leaves known implementation gaps in place; each is recorded here so it is not lost, and lands as its own follow-up change referencing this spec:
  1. Wire the completion cascade (`ReminderSegmentViewModel.toggleCompletion`, `DetailViewModel.toggleCompletion`/`bulkToggleCompletion`, `EditorViewModel.toggleSubtaskCompletion`) — the `completeDescendants()`/`uncompleteDescendants()` helpers currently have zero call sites.
  2. Fix delete cascade: no `.deleteRule(.cascade)` on the relationship; `TimelineViewModel.delete`/`bulkDelete` neither call `deleteDescendants()` nor delete children, so timeline deletions orphan subtasks.
  3. Implement the legacy flattening pass and depth-1 enforcement (drag-drop target validation; the recursive editor sheet currently permits creating depth-2 subtasks).
  4. Fix the two stale tests in `TaskFlowUITests/TaskFlowSubtasksUITests.swift` that expect dated subtasks hidden from the timeline (regressed expectation after commit `0549c0c` restored surfacing).
- **Archival note**: because this change defines target state, some requirements (cascades, flattening, depth enforcement) will not match code until the follow-ups above land. Archive this change together with — or after — those implementation changes.
