## Why

Today Wednesday Calendar (internal name "TaskFlow") is local-only SwiftData — a documented, deliberate decision (`decisions.md` 2026-02-10 "Remove iCloud Sync", 2026-09-09 "Prioritize Core Features And Data Safety Over Cloud Sync"). Users who switch between iPhone, iPad, and Mac re-enter the same tasks manually, and there is no path for the data to follow the user. Cloud sync is the highest-leverage retention feature the app can ship next, and the schema was kept CloudKit-compatible by discipline (optional scalars, no unique constraints) so this is a configuration + compatibility pass, not a rewrite.

## What Changes

- Enable SwiftData → CloudKit mirroring via a single shared private container (`iCloud.com.samson.wednesday`) for the one app bundle ID
- Bump the schema to a CloudKit-compatible `TaskFlowSchemaV10`: all attributes have property-level default values, all to-many relationships become optional (`[T]?`)
- Add iCloud + CloudKit entitlements and the ModelConfiguration `cloudKitDatabase:` wiring (silent sync — no sync-specific UI in v1)
- Make container creation crash-safe: fall back to a local-only store instead of `fatalError` if CloudKit load fails, so signed-out/entitled users keep working
- Keep previews/tests on local in-memory stores (no CloudKit in CI)
- Add sync-aware reconciliation: view-model refresh on remote merges, Inbox list dedupe, and data-gated (not flag-gated) sort-order backfill
- Document the non-goal: Timeline manual ordering stays device-local in v1

**BREAKING:** No — schema changes are lightweight-migratable from V9. Persistence model changes only.

## Capabilities

### New Capabilities
- `icloud-sync`: Cross-device sync of all persisted user data (tasks, lists, tags, groups) through SwiftData's CloudKit mirroring into a shared private container, with crash-safe local fallback when CloudKit is unavailable.

### Modified Capabilities
- `reminder-persistence-compatibility`: Schema evolution policy changes from "any lightweight migration is safe locally" to "production CloudKit schema is additive-only after promotion; all future changes must keep attribute defaults and optional relationships".

## Impact

- `TaskFlow/Models/TaskItem.swift` — new `TaskFlowSchemaV10`, typealiases, optional relationships, attribute defaults
- `TaskFlow/App/TaskFlowApp.swift` — `ModelConfiguration(cloudKitDatabase:)`, crash-safe fallback, `Schema(versionedSchema: V10)`
- `TaskFlow/Previews/TaskPreviewData.swift` — in-memory local config stays `.none`, schema bumped to V10
- `TaskFlow/TaskFlow.entitlements` — iCloud container identifiers + services (+ default container)
- `TaskFlow.xcodeproj/project.pbxproj` — `Debug`/`Release` `PRODUCT_BUNDLE_IDENTIFIER` consolidated to `com.samson.wednesday` (retire `com.samsonsunny.app.task-flow`); `SystemCapabilities` `com.apple.iCloud { CloudKit = 1; enabled = 1; }` so entitlements apply per-build-config
- **Call sites of now-optional relationships** — `ListView`, `EditorView`/`EditorViewModel`, `TimelineView`/`TimelineViewModel`, `DetailView`/`DetailViewModel`, `ListViewModel`, `CompletedView`/`CompletedViewModel`, `ListSection`, `Draft`, list-picker/groups views (unwrap `?? []`, or small computed helpers)
- `TaskFlow/App/ContentView.swift` — Inbox dedupe reconciler at launch
- `TaskFlow/Models/SortOrderBackfill.swift` — data-gated backfill
- View refresh on remote merges — `TimelineView`, `DetailView`, `ListView`, `EditorView`, `CompletedView` (+ the no-save toggle in `DetailViewModel.toggleCompletion`)
- `decisions.md` — new decision reversing the "defer sync" stance
- Apple Developer portal (manual, external) — CloudKit container registration for both App IDs
- Tests — `TaskFlowTests`/`TaskFlowUITests` keep local containers; schema-related unit tests updated