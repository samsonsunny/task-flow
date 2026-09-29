# areas-inbox-remove-global — Design

## Context

Today a single global `ReminderList` named "Inbox" (`ReminderDefaults.defaultListName`) serves as the neutral capture zone. It is found by *name* in ~8 production sites (`ContentViewModel` migrations, `InboxReconciler`, `ListSection`, `SortOrderBackfill`, `CaptureBarViewModel`, `ListView`/`ListViewModel` guards, `EditorView`/`ListPickerView` icons, `Draft` resolution, `TaskItem.listName` fallback). Everything else — groups, lists, tasks — already lives in `ReminderList`/`ReminderListGroup` SwiftData models. `ReminderListGroup` (the "area") is single-level and already rendered as expandable sections.

The product direction: every area owns an "Inbox" bucket so capture is scoped to an area, and the global list disappears entirely. Because every bucket is named "Inbox", *name* can no longer be the identity — pointer identity (`ReminderListGroup.defaultListID`) becomes the mechanism.

Constraints:
- MVVM (AGENTS.md): views never mutate; ViewModels own logic; ViewModels receive `modelContext` at init; Views hold `@Query`; every mutation calls `update()` after `save()`.
- Schema changes use implicit lightweight migration — **no `migrationPlan:`** (AGENTS.md), add property to the latest schema (`TaskFlowSchemaV10`), update `TaskFlowApp.swift` + `TaskPreviewData.swift` `Schema(versionedSchema:)`.
- SwiftData relationship inverse conventions already in place: `ReminderList.group` ↔ `ReminderListGroup.lists`.

## Goals / Non-Goals

**Goals:**
- Every `ReminderListGroup` has exactly one identified Inbox bucket (`defaultListID`), created on migration and on group creation.
- Remove the global "Inbox" list concept and *all* name-based Inbox detection.
- Lossless, idempotent, one-time migration that preserves every task (completed included) via list reparenting — never deletion, never per-task rewrites.
- Migration destination deterministic: first group by `sortOrder` then `createdAt`.
- Capture fallback (`.inbox`) resolves to the first group's Inbox bucket via pointer.
- Fresh/empty stores seed Work + Personal areas with buckets.

**Non-Goals:**
- Renaming a bucket ("Set as Default" on a custom list, renaming "Inbox") — deferred to v2 of the pointer-tracked model.
- Deleting an area's Inbox bucket — protected in this change.
- UI for assigning capture to a *specific non-bucket* list inside an area from a time segment — out of scope here.
- The full "areas as the primary home screen" navigation step — separately planned.

## Decisions

### D1. Pointer-identity: `ReminderListGroup.defaultListID` (schema addition)

Add an optional to-one relationship `defaultList: ReminderList?` on `ReminderListGroup` (inverse `\ReminderList.defaultForGroup`, single-valued), or equivalently a scalar `defaultListID` of the list's `persistentModelID` type. Prefer the **relationship** form: SwiftData–native, survives CloudKit mirroring naturally, and gives typed access to the bucket without a second fetch.

Rationale vs alternatives:
- *Name-based lookup* (current) — rejected: multiple "Inbox" lists become ambiguous; `InboxReconciler` would treat one area's bucket as a duplicate and delete it.
- *New top-level `ReminderArea` model* — rejected: forces relocation of existing groups, two "unlisted" flavors, more schema churn than reusing `ReminderListGroup`.
- *No default; nil-list + `TaskItem.area`* — rejected: breaks the "every task has a list" invariant enforced by orphan sweeps.

Invariant: `group.defaultList == nil || group.defaultList?.group == group`. Enforced by the reconciler and the "bucket moved out" guard on `ReminderList.group` mutation (group-bucket lists cannot be moved via the Move-to-Group UI in this change).

### D2. Migration: reparent, never destruct

A one-time `migrateGlobalInboxToFirstGroup` runs before rendering, keyed in `UserDefaults` (pattern of `did_migrate_default_list_name_v1`; flag written **after** successful `modelContext.save()`):

1. Fetch groups sorted by `sortOrder` then `createdAt`; `firstGroup = groups.first`.
2. If `groups.isEmpty`: create **Work** then **Personal** (assign `sortOrder`), each with a bucket `ReminderList("Inbox")` + `defaultList` pointer. `firstGroup = Work`.
3. Find the global "Inbox" list (`name == "Inbox"` && `group == nil`, and — if present — the bucket identity is still by name here because this is the *only* remaining name lookup during migration). Reparent: `globalInbox.group = firstGroup`, `firstGroup.defaultList = globalInbox`. Zero task touches; all tasks, dates, flags, sort orders preserved in the relationship.
4. Reparent remaining `group == nil` lists (non-bucket) into `firstGroup` the same way.
5. If `firstGroup` already has a bucket (defensive edge), merge bucket tasks in and delete the stale list.

Rationale: reparenting the whole list preserves `createdAt`, `sortOrder`, task relationships, and completed state with no per-row writes — the only lossless option that can't drop a task. Deleting-and-recreating would risk losing `sortOrder` and CloudKit change tokens.

First-group determinism: `sortOrder` (fractional string, sideBar order) then `createdAt` — stable across re-runs, matches visible sidebar order, mirrors the capture default.

### D3. Reconciler backstop (replaces `InboxReconciler`)

`reconcileAreaInboxes(in:)` on every launch:
- For each group with no bucket: create bucket + pointer.
- Recurring sweep: any `TaskItem` with `reminderList == nil` (or pointing at a deleted list) → first group's bucket.
- Any floating "Inbox" bucket (group==nil leftover) → reparent to first group.

This is the safety net for partial-failure or CloudKit edge states, so orphaned data can never strand. `InboxReconciler`'s "merge duplicate Inbox lists" logic is removed — duplicates are now *expected* (one per area) and must not be collapsed.

### D4. Capture resolution chain (`.inbox` → first group's bucket)

`CaptureBarViewModel.resolveTargetList`:
- `.list(id)` → that list (unchanged).
- `.inbox` → first group (by `sortOrder`→`createdAt`) → its `defaultList`; if none found, resolve via the reconciler/creation path (create Work+Personal+buckets if store empty).
- Removes the `name == ReminderDefaults.defaultListName` fetch and the inline list creation.

The `CaptureTarget.inbox` case stays but now means "the default area's bucket." The same resolver is used by `TimelineViewModel`'s fallback.

### D5. Sidebar/display: bucket under its group; name-based guards → pointer

- `buildListSections`: for each group, its bucket is pinned first (via `defaultList`), then remaining member lists. The standalone "default" section and the `ungrouped` section disappear — every list has a group after migration; the ungrouped filter in `ListViewModel.ungroupedLists` and sidebar logic is removed.
- `ListView`/`ListViewModel`: "is Inbox" checks become `list == list.group?.defaultList`. The protected-bucket rules (no rename/delete/tray icon) key on that pointer, not `name`.
- `SortOrderBackfill.backfillListSortOrdersIfNeeded`: drop the `name == defaultListName` special-case; ordering is now purely `sortOrder` within groups (buckets seed first via migration assignInitialSortOrder).

### D6. Editor/picker disambiguation

- `EditorView`/`ListPickerView` tray icon: keys on the bucket pointer with one small addition — when rendering lists inside a group, prefix the list with its group name for context ("Work · Inbox"), since bare "Inbox" is now ambiguous.
- `Draft` list resolution: replace name-string resolution with persistentModelID resolution (the new bucket is a real list with a stable ID).

### D7. Fixtures & tests

`TaskPreviewData.ensureDefaultListExists` is replaced by `seedDefaultAreas`: creates Work + Personal with buckets. `seedReminderHomeFixture` uses the same. Tests asserting a name-based global Inbox (`DraftTests`, `SyncReadinessTests`, UITests, `testCaptureBarPresentOnSidebar`) are updated to assert first-group-bucket behavior.

## Risks / Trade-offs

- **Name collisions during migration** (a user's custom list is already named "Inbox") → The migration targets the bucket by `group == nil` + name only *once*, before any bucket exists; D3 reconciler is idempotent. A custom "Inbox" list inside a group is left alone (only the global list is reparented).
- **CloudKit in flight** (`icloud-sync` change) intersecting a schema/relationship addition → coordinate ordering; the relationship addition is a lightweight schema change; reconciler sweep handles inter-device divergence. Sequence this change's build after `icloud-sync` lands (or stage the model first).
- **Merge onto existing workflows** (global-capture-bar, lists-sidebar-split in progress) → this change builds on their outcomes; the `CaptureBallViewModel`/sidebar edits assume the post-split structure. Confirm branches are integrated before apply.
- **Bucket pinned-first changes existing group ordering** → buckets receive `assignInitialSortOrder` first, so they appear at the top of each group; existing member-list relative order is untouched by D2 partial re-index.
- **Migration target list may be renamed later (v2 "Set as Default")** → all consumer code reads `defaultList` at use-time, so a later repoint is a single property write with no schema change.

## Migration Plan

1. **Order**: schema addition (+ implied lightweight migration) → `seedDefaultAreas`/migration run-once → reconciler → UI. All within the same released build; the `UserDefaults` flag gates re-runs.
2. **Rollback**: reverting the build before the flag is set restores prior behavior; after the flag is set (migration saved), data is already in the new shape and is forward-compatible. Nothing destructively edited — a revert build simply sees a group with a bucket instead of a global list.
3. **Verification**: migration unit tests (three cases: groups exist / no groups / empty store), idempotency test (re-run no-op), CloudKit smoke test for relationship sync.

## Open Questions

- Exact display name of seeded areas ("Work"/"Personal") — confirmed intent in proposal; keep customizable via existing rename-group UI after migration.
- Whether the `.inbox` capture target chip should show area context ("Work · Inbox") on compact widths — resolves to D6 disambiguation for now.
- Sequencing with `icloud-sync` and whether we gate this build behind it.