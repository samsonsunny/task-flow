## 1. Authoritative `task-subtasks` spec delta

- [x] 1.1 Data rules: parent-child relationship (full TaskItem, inherits parent's list, cycle-free, depth ≤ 1)
- [x] 1.2 Lifecycle rules: completion cascade down incl. notification cancel, no auto-complete up, uncomplete reversal, delete cascade at every site (single + bulk + all surfaces)
- [x] 1.3 Display rules: flat list-detail rows with M/N fraction; editor as management surface; dated-only time-tab surfacing
- [x] 1.4 Interaction rules: drag-reparent constraints (sibling insert on subtask targets), midpoint reorder, Move-to-List promotion
- [x] 1.5 Legacy flattening requirement: detach below-depth-1 descendants to independent top-level tasks; idempotent; preserve everything but the link
- [x] 1.6 Consolidated Limitations (non-goals) requirement
- [x] 1.7 Remove dead "List view displays nested tasks hierarchically" requirement

## 2. Mental-model reconciliation

- [x] 2.1 Rewrite base `app-mental-model` "Subtasks in time tabs" block: dated-only surfacing, flat rows, fraction on parent rows, no inline trees
- [x] 2.2 Update the navigation tab table (Today/Tomorrow/Upcoming rows) to drop "subtasks inline (expandable/collapsible)"

## 3. Housekeeping

- [x] 3.1 Delete `openspec/changes/subtasks-in-time-tabs/` (implemented, then reverted by commit `72f901d`, never archived)
- [x] 3.2 Cross-check artifacts against AGENTS.md conventions and shipped UI

## 4. Validation

- [x] 4.1 `openspec validate --strict` passes for this change
- [x] 4.2 Read-through: no requirement contradicts shipped UI or another spec; follow-up implementation list present in proposal

## Archival note

Archive together with — or after — the follow-up implementation changes listed in the proposal (cascade wiring, delete-cascade fixes, flattening migration + depth enforcement, stale UI tests), so the merged base spec never describes unimplemented behavior for long.
