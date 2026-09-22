## 1. Bundle Consolidation, Developer Portal & Entitlements

- [ ] 1.1 Repoint `Debug` and `Release` `PRODUCT_BUNDLE_IDENTIFIER` to `com.samson.wednesday` in `TaskFlow.xcodeproj/project.pbxproj` (single App ID, remove `com.samsonsunny.app.task-flow`)
- [ ] 1.2 Add `SystemCapabilities` → `com.apple.iCloud { CloudKit = 1; enabled = 1; }` to the TaskFlow target's build settings in pbxproj
- [ ] 1.3 Create CloudKit container `iCloud.com.samson.wednesday` in Apple Developer portal (manual)
- [ ] 1.4 Add iCloud + CloudKit capability to App ID `com.samson.wednesday` (now the only app bundle) with the container as default (manual)
- [ ] 1.5 Add iCloud keys to `TaskFlow/TaskFlow.entitlements`: `com.apple.developer.icloud-container-identifiers` = `[iCloud.com.samson.wednesday]` and `com.apple.developer.icloud-services` = `[CloudKit]` (no `icloud-container-default-container-identifier` — the dev profile omits it and SwiftData names the container explicitly)

## 2. Schema V10 (CloudKit-compatible model)

- [ ] 2.1 Add `TaskFlowSchemaV10` to `TaskFlow/Models/TaskItem.swift` as a copy of V9 with property-level defaults: `ReminderList.name = ""`, `.createdAt = Date()`, `ReminderTag.label = ""`, `.normalizedLabel = ""`, `ReminderListGroup.name = ""`, `.createdAt = Date()`
- [ ] 2.2 Make to-many relationships optional in V10: `ReminderList.reminders`, `TaskItem.subtasks`, `TaskItem.tags`, `ReminderListGroup.lists` → `[T]?` (keep init defaults `= []` and existing `@Relationship(inverse:)` declarations)
- [ ] 2.3 Update the four `typealias`es to point at V10
- [ ] 2.4 Update `Schema(versionedSchema:)` to V10 in `TaskFlowApp.swift` and `TaskPreviewData.swift` (no `migrationPlan:` per AGENTS.md)
- [ ] 2.5 Add computed convenience accessors for optional arrays (e.g. `remindersArray`, `subtasksArray`, `tagsArray`, `listsArray`) as needed
- [ ] 2.6 Migrate all call sites of the now-optional arrays in `ListView`, `EditorView`/`EditorViewModel`, `TimelineView`/`TimelineViewModel`, `DetailView`/`DetailViewModel`, `ListViewModel`, `CompletedView`/`CompletedViewModel`, `ListSection`, `Draft`, list-picker and group views
- [ ] 2.7 Grep for `.deny` delete rules and any `@Attribute(.unique)` remaining in the schema; confirm none exist
- [ ] 2.8 Run the full unit + UI test suite to confirm V10 and the array ripple break nothing (CloudKit not wired yet)

## 3. CloudKit Wiring

- [ ] 3.1 Rebuild `sharedModelContainer` in `TaskFlowApp.swift` with `ModelConfiguration("wednesday", cloudKitDatabase: .private("iCloud.com.samson.wednesday"))` against `Schema(versionedSchema: TaskFlowSchemaV10.self)`
- [ ] 3.2 Replace the `fatalError` with a crash-safe fallback that retries with `cloudKitDatabase: .none` (same schema/URL) and logs loudly; keep `fatalError` only if the fallback fails
- [ ] 3.3 Confirm `TaskPreviewData.container()` and all test containers stay `isStoredInMemoryOnly: true` with `.none` (no CloudKit in previews/tests/CI)
- [ ] 3.4 Keep the orphan `CloudKit.framework` reference untouched unless the linker/runtime surfaces an issue

## 4. Sync-Aware Behavior Fixes

- [ ] 4.1 Add an app-wide `NotificationCenter` observer for `ModelContext.didSave` and wire views (`TimelineView`, `DetailView`, `ListView`, `EditorView`, `CompletedView`) to call their ViewModel's `update()` on remote merges
- [ ] 4.2 Fix `DetailViewModel.toggleCompletion` (currently mutates without saving) to call `modelContext.save()`
- [ ] 4.3 Add an idempotent Inbox reconciler: on launch, merge tasks from duplicate `ReminderList(name: "Inbox")` records into one and delete extras (attribute-driven, runs every launch)
- [ ] 4.4 Change `backfillSortOrdersIfNeeded` to be data-gated: only assign `sortOrder` to tasks where it is nil, instead of rewriting all tasks behind a UserDefaults flag; confirm the list backfill is already data-gated

## 5. Tests & Verification

- [ ] 5.1 Add/update unit tests for V10 model defaults and optional relationship handling
- [ ] 5.2 Add a unit test for the Inbox reconciler merging duplicate lists without losing tasks
- [ ] 5.3 Add a unit test proving `backfillSortOrdersIfNeeded` preserves existing sort orders
- [ ] 5.4 Run unit + UI suites locally against in-memory `.none` containers
- [ ] 5.5 Build and run in simulator with a seeded store; watch console for CloudKit schema errors (134060/134100) on first cloud launch and confirm the `tags` relationship mirrors without an explicit inverse
- [ ] 5.6 Two-simulator shared-iCloud test: create on A → appears on B; delete on A → removed on B; list moves / subtask nesting / tag edits / completion toggle propagate
- [ ] 5.7 Real-device tests: fresh install pulls cloud data; existing local store uploads; offline edits merge on reconnect; ordering after conflicting inserts
- [ ] 5.8 Verify the single bundle ID `com.samson.wednesday` across Debug and Release configs loads the CloudKit container
- [ ] 5.9 Promote the CloudKit dev schema to production in the CloudKit Console before App Store submission
- [ ] 5.10 Record a new decision in `decisions.md` reversing the "defer sync" stance with the container and constraints adopted

## 6. Known Limitations (documented, not implemented in v1)

- [ ] 6.1 Document in design/docs that Timeline manual ordering (Today/Tomorrow/Overdue, stored in `UserDefaults` keyed by `persistentModelID`) is device-local and does not sync; note the follow-up option to promote ordering into model attributes