# areas-inbox-remove-global

## Why

"Areas" (the `ReminderListGroup` in the mental model) currently have no ownership of new/uncategorized tasks — that role is held by a single global "Inbox" list that sits outside every group, is found by *name* in ~8 places, and breaks down the moment two groups both want a neutral capture zone. The end-state the product is moving toward: every area owns its own permanent "Inbox" bucket, capture lands in the current area's bucket, and there is no global list at all.

## What Changes

- **Every group owns an Inbox bucket.** `ReminderListGroup` gains a pointer to its default list (`defaultListID`). The bucket list is named "Inbox", lives inside its group's section, and is protected (no rename/delete in v1).
- **Identity by pointer, not name.** Because every area's bucket is named "Inbox", no code may find "the Inbox" by name. All name-based Inbox detection is retired: `ReminderDefaults.defaultListName`, `InboxReconciler`'s name filter, name-based list pinning in `ListSection`/`SortOrderBackfill`/`ListView`/`EditorView`/`ListPickerView`, and the `.inbox` capture target's name lookup.
- **Global Inbox removed via lossless migration.** On launch after update, the existing global "Inbox" list is **reparented** (not deleted, not rewritten task-by-task) into the first group as that group's Inbox bucket: `list.group = firstGroup; firstGroup.defaultListID = list`. Every task — completed or not, with all dates/flags/sort order — rides along in the relationship. **No task data can be lost.**
- **Legacy ungrouped lists reparent too.** Lists with `group == nil` are reparented into the first group, so every list has an area.
- **Default areas for empty stores.** If no group exists, the migration seeds **Work** and **Personal** (each with an Inbox bucket) and then reparents the global Inbox into Work's bucket. A fresh install therefore already shows the two canonical areas. **(BREAKING for setup flow.)**
- **Reconciler backstop.** A reconciler (replacing `InboxReconciler`) re-creates a missing area bucket and sweeps area-less/nil-list tasks into the *first group's* Inbox, so data can never strand.
- **Idempotent, guarded.** Migration runs once, keyed the same way as `did_migrate_default_list_name_v1`/`did_migrate_orphaned_tasks_v1`, with the flag set only after successful save.
- **Capture targets the area, not a global list.** `.inbox` capture (sidebar overview, time segments) resolves to the *first group's* Inbox bucket instead of a name-matched global list. Capture inside a group's detail keeps targeting its bucket via the pointer.

## Capabilities

### New Capabilities

- `areas-inbox`: Group-owned Inbox buckets — `ReminderListGroup.defaultListID` pointer identity, "Inbox" bucket display/creation/protection rules, seed-default migration (Work/Personal), and the first-group fallback rule.

### Modified Capabilities

- `list-groups`: Group sections now include each group's Inbox bucket (pinned first in the group via pointer, protected); group creation provisions the bucket; ungrouped lists are migrated into the first group.
- `quick-capture`: The `.inbox` default target resolves to the first group's Inbox bucket (pointer-based) instead of the name-matched global Inbox; the "create Inbox if missing" fallback becomes "create/use first group's bucket".
- `app-mental-model`: The "default list is called Inbox" single-global concept is replaced by per-area Inbox buckets; the Later tab's neutral landing zone is each area's Inbox (default capture: first group's Inbox).
- `list-management`: Protected-list rules move from the single name-matched "Inbox" to pointer-identified area buckets (no rename/delete for any area's Inbox in v1); delete-cascade targets become area-relative; list sort-order backfill special-cases "Inbox-first" in favor of group-relative ordering.

## Impact

- `TaskFlow/Models/TaskItem.swift` — add `defaultListID` to `ReminderListGroup` (latest schema, implicit lightweight migration per AGENTS.md); remove `ReminderDefaults.defaultListName`.
- `TaskFlow/App/ContentView.swift` — `migrateDefaultListName`/`migrateOrphanedTasks` replaced by the reparent migration + seed-defaults; reconciler call stays.
- `TaskFlow/Models/InboxReconciler.swift` — becomes the area-bucket reconciler (create-missing-bucket, sweep-nil-list).
- `TaskFlow/Models/ListSection.swift` — group sections pin each group's bucket first via `defaultListID`; name-based default pin removed.
- `TaskFlow/Models/SortOrderBackfill.swift` — Inbox-name special-casing in list sort backfill removed.
- `TaskFlow/Views/Components/CaptureBarViewModel.swift` — `.inbox` resolves to first group's bucket.
- `TaskFlow/Features/Lists/ListView.swift`, `ListViewModel.swift` — sidebar shows bucket under its group; guards move from `name == Inbox` to pointer checks.
- `TaskFlow/Features/Lists/DetailView.swift`, `DetailViewModel.swift` — unchanged filter (bucket is a real list; renders through the reused detail).
- `TaskFlow/Features/Editor/EditorView.swift`, `ListPickerView.swift`, `Draft.swift` — drop name-based Inbox icon/resolution; pickers show area context for disambiguation.
- `TaskFlow/Features/Tasks/Timeline/TimelineViewModel.swift` — Inbox fallback becomes first-group bucket resolution.
- `TaskFlow/Previews/TaskPreviewData.swift` — fixtures seed Work/Personal areas with buckets instead of a global Inbox.
- Tests: `DraftTests`, `SyncReadinessTests`, UITests that assert a name-based global Inbox.