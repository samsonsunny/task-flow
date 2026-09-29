## 1. Model & Schema

- [x] 1.1 Add `defaultList: ReminderList?` relationship on `ReminderListGroup` (`@Relationship(inverse: \ReminderList.defaultForGroup)`) and matching `defaultForGroup: ReminderListGroup?` on `ReminderList`, plus a `var inboxBucket` convenience accessor on `ReminderListGroup` that returns `defaultList`. Add to `TaskFlowSchemaV10` models (implicit lightweight migration, no `migrationPlan:` per AGENTS.md).
- [x] 1.2 Update `TaskFlowApp.swift` and `TaskPreviewData.swift` `Schema(versionedSchema:)` references to the schema containing the new property (bump to the added schema version if a new enum, else keep V10).
- [x] 1.3 Protect the invariant `group.defaultList == nil || group.defaultList?.group == group` in the "move list to group" mutation (`ListViewModel.assignListToGroup` / `moveLists`) by refusing to move a bucket (per spec list-groups).

## 2. Retire name-based Inbox identity

- [x] 2.1 Remove `ReminderDefaults.defaultListName` and all `name == ReminderDefaults.defaultListName` comparisons; replace with pointer checks (`list == list.group?.defaultList`) in `ListView`, `ListViewModel`, `EditorView`, `ListPickerView`.
- [x] 2.2 Delete `migrateDefaultListName()` from `ContentView` (the Reminders→Inbox rename is obsolete; migration now handled by reparent logic).
- [x] 2.3 Replace `InboxReconciler` with `reconcileAreaInboxes` (create missing bucket per group, reparent floating `group == nil` Inbox lists to first group, sweep nil-list tasks — spec areas-inbox) and update the call site in `ContentView`.
- [x] 2.4 Remove the `name == defaultListName` special-case from `SortOrderBackfill.backfillListSortOrdersIfNeeded`; order by group-relative (bucket first, then name, then createdAt) per spec list-management.

## 3. Migration: global Inbox → first group

- [x] 3.1 Implement `migrateGlobalInboxToFirstGroup(in:)`: guarded by a UserDefaults key (set only after successful `save()`); fetches groups sorted by `sortOrder` then `createdAt`; reparents the global `group == nil` "Inbox" list into the first group via `list.group = firstGroup; firstGroup.defaultList = list` (zero task writes).
- [x] 3.2 When no groups exist: seed `Work` and `Personal` groups with `sortOrder` and an Inbox bucket each; reparent the global Inbox into Work's bucket (spec areas-inbox, app-mental-model).
- [x] 3.3 Reparent all remaining `group == nil` lists (non-bucket) into the first group (design D2 step 4).
- [x] 3.4 Defensive merge: if the first group already has a bucket, merge bucket tasks into it and delete the stale global list.
- [x] 3.5 Add migration unit tests: (a) groups exist path, (b) no-groups/dry-store path, (c) idempotency (re-run no-op), (d) no `TaskItem` is modified/deleted (compare before/after list membership, flags, dates, sortOrder).

## 4. Sidebar & list section rendering

- [x] 4.1 Update `buildListSections` to pin each group's bucket first (via `defaultList` pointer) and drop the standalone "default" section and the `ungrouped` section (every list now has a group).
- [x] 4.2 Update `ListView`/`ListViewModel` sidebar: render the bucket under its group with the tray icon; suppress rename/delete/move-to-group context actions and drag on buckets (pointer-based guards; spec list-management, list-groups).
- [x] 4.3 Update `ListsTabViewModel` derived state (`ungroupedLists` filter, Inbox lookups) for the new model; call `update()` after every bucket-touching save per MVVM conventions.

## 5. Capture resolution

- [x] 5.1 Rework `CaptureBarViewModel.resolveTargetList` for `.inbox` to resolve the first group (sortOrder → createdAt) and return its `defaultList`; if store empty, create Work/Personal+buckets via the shared seed path (spec quick-capture). Remove the `name == defaultListName` fetch and inline list creation.
- [x] 5.2 Update `TimelineViewModel`'s Inbox fallback (line ~172) to use the same first-group-bucket resolver.
- [x] 5.3 Add capture resolution tests: overview capture → first group's bucket, empty-store capture seeds areas, list capture unchanged, bucket capture assigns to that bucket.

## 6. Editor & picker disambiguation

- [x] 6.1 Update `EditorView`/`ListPickerView` tray-icon checks to the bucket pointer; render list rows with group context (e.g., "Work · Inbox") when the list is a bucket (design D6).
- [x] 6.2 Replace `Draft`'s name-string list resolution with persistentModelID resolution (design D6) so buckets resolve by identity.

## 7. Fixtures & previews

- [x] 7.1 Replace `TaskPreviewData.ensureDefaultListExists` with a `seedDefaultAreas` helper (Work/Personal + buckets); update `ensureDefaultListExists` call sites in previews.
- [x] 7.2 Update `seedReminderHomeFixture` and any fixtures that create a global "Inbox" to the seeded-areas shape.

## 8. Test suite & verification

- [x] 8.1 Update tests asserting a name-based global Inbox: `DraftTests`, `SyncReadinessTests`, `TaskPreviewData`-based assertions.
- [x] 8.2 Update `list-management`/`quick-capture`/`app-mental-model` spec-scenario tests (rename/delete guards on buckets, overview-capture target, backfill ordering).
- [x] 8.3 Update `TaskFlowUITests` (`testCaptureBarPresentOnSidebar` and any Inbox-name assertions) to first-group-bucket behavior.
- [x] 8.4 Run full test suite; verify migration idempotency and that no task is orphaned after a simulated CloudKit divergence (nil-list sweep).

## 9. Sequencing & docs

- [x] 9.1 Confirm `global-capture-bar` and `lists-sidebar-split` are integrated before apply (this change edits `CaptureBarViewModel`, `MainTabView`, `ListView`).
- [x] 9.2 Coordinate the relationship addition with the in-flight `icloud-sync` change (schema/CloudKit collision check) or stage the model change first.
- [x] 9.3 Update `openspec/specs/app-mental-model/spec.md` global-Inbox prose and `openspec/specs/list-groups`/`list-management` archived deltas after apply.