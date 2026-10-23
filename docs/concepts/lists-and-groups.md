# Concept: Domains, Lists & Projects

**Model:** Exactly two permanent domains, Work and Personal. Projects/lists are optional organization inside a domain.
**Canonical spec:** `openspec/specs/app-mental-model/spec.md`

## Purpose

The app has two fixed domains. Users file tasks into a domain either directly (into that domain's Inbox) or into a project/list inside it. There is no third domain and no user-created top-level group.

`ReminderListGroup` is the legacy SwiftData type for a domain. `ReminderList` is a project/list inside one domain. The type names stay for CloudKit schema compatibility; product language should say "domain" and "project/list".

## Code map

| File | Role |
|---|---|
| `TaskFlow/Models/AreaReconciler.swift` | Seeds/locks Work and Personal, derives Inbox buckets, repairs invalid data |
| `TaskFlow/Models/TaskItem.swift` | `ReminderListGroup` (domain) and `ReminderList` (project/list) models |
| `TaskFlow/Features/Areas/AreaTasksView.swift` + `AreaTasksViewModel.swift` | Work/Personal task surface (list + board modes) |
| `TaskFlow/Features/Lists/ListView.swift` + `ListViewModel.swift` | Domain-scoped list management: create, rename, delete, reorder |
| `TaskFlow/Features/Lists/DetailView.swift` + `DetailViewModel.swift` | Task surface inside one list |
| `TaskFlow/Features/Settings/MoreView.swift` + `MoreViewModel.swift` | More tab: domain list management, Completed, settings |
| `TaskFlow/Utilities/SortOrderMidpoint.swift` | Shared midpoint/widen ordering |

## Domain rules

- Work and Personal always exist.
- Domains are identified by canonical stored names (`AreaNames.work`, `AreaNames.personal`).
- Domains cannot be created, renamed, deleted, or reordered in the UI.
- Each domain owns exactly one protected Inbox bucket, pinned first.
- Any extra `ReminderListGroup` is folded into Work on launch; its lists survive and its bucket tasks move to Work Inbox.
- No new model field marks a domain or bucket. Identity is derived from names and membership because the CloudKit production schema is sealed.

## List rules

- Every list belongs to exactly one domain; ungrouped lists are invalid and repaired into Work.
- A list's domain is fixed at creation. There is no cross-domain drag or picker.
- Lists can be created, renamed, deleted, and reordered only inside their domain.
- Deleting a list either moves its tasks to the owning domain's Inbox or deletes them with confirmation.
- Projects/lists never become root tabs.

## Responsibilities of ListViewModel

### Derived state (`update(lists:groups:allTasks:)`)
- Lists in a domain, ordered with the Inbox bucket first.
- Bucket detection via `ReminderList.isBucket`; protected-domain detection via `ReminderListGroup.isLocked`.

### Mutations
- `createList(name:in:)` — always takes an explicit domain.
- `renameList(_:to:)` and `deleteList(_:moveTasksTo:)` / `deleteListAndTasks(_:)`.
- `moveLists(fromOffsets:toOffset:in:)` — only within one domain.

## Responsibilities of DetailViewModel

### Derived state
- Flat task tree honoring collapse state.
- Completion animation and `refreshNow()` timer hook.

### Mutations
- Completion, delete, quick capture, move to another list, schedule.
- Drag/drop reorder, nesting, and re-parenting with `isDescendant(_:of:)` cycle guard.
- Bulk reschedule/move/complete/delete/priority.

## Invariants worth preserving

1. **Two domains only.** Do not add a third `ReminderListGroup` or a "New Project" action that creates a group.
2. **Inbox is per domain.** Never fall back to a global Inbox or another domain's bucket.
3. **Lists never change domain.** Cross-domain moves need an explicit product decision and migration.
4. **Delete semantics are explicit.** Move tasks to Inbox or delete them; never orphan.
5. **A task can never become its own descendant.** Check `isDescendant(_:of:)` before re-parenting.
6. **Midpoint/widen only** for ordering; never renumber whole sibling sets.
7. **Domain names are load-bearing.** Do not rename Work/Personal in data; only the display label can change (Personal, not Home).
