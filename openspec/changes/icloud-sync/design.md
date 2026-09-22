## Context

Wednesday Calendar (internal name "TaskFlow") is a local-only SwiftData app. Two prior decisions in `decisions.md` removed CloudKit (`2026-02-10`) and deferred sync in favor of a local Export/Restore (`2026-09-09`), while committing to a CloudKit-compatible schema as "a background discipline." That discipline mostly paid off: there are no `@Attribute(.unique)` constraints and all scalar attributes are optional. Two incompatibilities remain, both mechanical:

1. **Attributes without property-level defaults.** `ReminderList.name`, `ReminderTag.label`, `ReminderTag.normalizedLabel`, `ReminderListGroup.name`, and the non-optional `createdAt` fields are required attributes with no default at the schema level. CloudKit mirroring rejects these (load error 134060).
2. **Non-optional to-many relationships.** `ReminderList.reminders`, `TaskItem.subtasks`, `TaskItem.tags`, `ReminderListGroup.lists` are declared as `[T]`. CloudKit requires *every* relationship — including to-many arrays — to be optional.

The app also has device-local behaviors that assume a single device: UserDefaults-flag-gated sort-order backfills, a name-based "Inbox" list seed that can race across devices, ViewModel state that only recomputes after local mutations, and Timeline manual ordering stored in `UserDefaults` keyed by local `persistentModelID`.

## Goals / Non-Goals

**Goals:**
- Enable silent, automatic cross-device sync of all persisted user data via SwiftData's CloudKit mirroring into a single shared private container.
- Make the schema CloudKit-compatible (V10) with the least disruptive API ripple.
- Keep the app crash-safe and functional when CloudKit is unavailable (signed out, entitlements broken, schema mismatch).
- Fix the sync-aware behaviors that would visibly misbehave (Inbox dedupe, refresh on remote merge, backfill churn) within v1.
- Keep previews, tests, and CI on local in-memory stores.

**Non-Goals:**
- No sync-specific UI (status banners, indicators, settings surface) in v1 — silent per product decision.
- No iCloud account-status detection or recovery UX.
- No migration of "Timeline manual order" (Today/Tomorrow/Overdue ordering in `UserDefaults`) into synced model data — documented limitation with a follow-up option.
- No district-level conflict resolution UI; v1 relies on CloudKit's last-writer-wins per-field merge.
- No import/export feature (that stays a separate potential change).

## Decisions

### D1: One CloudKit container, one App ID
Consolidate the app to a single bundle ID `com.samson.wednesday` by repointing the `Debug` and `Release` `PRODUCT_BUNDLE_IDENTIFIER` settings (retiring `com.samsonsunny.app.task-flow`), and use one container `iCloud.com.samson.wednesday`. SwiftData picks the container from entitlements; we pass it explicitly via `ModelConfiguration(cloudKitDatabase: .private("iCloud.com.samson.wednesday"))` rather than relying on `automatic` first-identifier discovery.
- **Why a single App ID:** the second bundle only existed to give dev builds a "throwaway" install separate from the store app. One App ID = one iCloud registration, one notifications path, one container to promote, simpler entitlements. The three build configs and their schemes stay intact — this is a signing/entitlement change, not a build-system rewrite.
- **Tradeoff:** a dev build on a physical device now replaces the installed Wednesday Calendar (same bundle ID) and shares its iCloud store. Day-to-day dev stays in Simulator.
- **Tracked:** App ID `com.samson.wednesday` must have the container set as default in the Developer portal, and the production schema must be promoted before App Store release.

### D2: Schema V10 with optional relationships, matching schema discipline intact
Add `TaskFlowSchemaV10` in `TaskItem.swift` as a copy of V9 with:
- Property-level defaults: `ReminderList.name = ""`, `.createdAt = Date()`; `ReminderTag.label = ""`, `.normalizedLabel = ""`; `ReminderListGroup.name = ""`, `.createdAt = Date()`.
- Optional to-many relationships: `reminders: [TaskItem]?`, `subtasks: [TaskItem]?`, `tags: [ReminderTag]?`, `lists: [ReminderList]?`.

Keep existing `@Relationship(inverse:)` declarations (`reminderList`/`reminders`, `parentTask`/`subtasks`, `group`/`lists`). `tags` has no declared inverse — accept the SwiftData-inferred inverse; verify at first cloud launch that the schema mirrors cleanly, and if not, add a back-reference `@Relationship(inverse: \TaskItem.tags) var tasks: [TaskItem]?` on `ReminderTag`.
- **Why optional arrays instead of keeping `[T]`:** CloudKit requires it; non-optional arrays fail container load (widely documented, error 134060).
- **Ripple containment:** keep init defaults `= []` and add computed convenience accessors (e.g., `var remindersArray: [TaskItem] { reminders ?? [] }`) so call sites can migrate mechanically where Swift minimalism allows, instead of sprinkling `?? []` everywhere.
- **Migration:** V9→V10 is a lightweight migration (required→optional relationship + the default additions are lightweight-compatible). Per AGENTS.md we do **not** pass `migrationPlan:` — keep `Schema(versionedSchema: TaskFlowSchemaV10.self)`.

### D3: Crash-safe container creation
Today `TaskFlowApp.sharedModelContainer` ends in `fatalError`. With CloudKit enabled, container creation can fail for user-facing reasons (signed out, schema mismatch, entitlements). Handle in order: try the CloudKit config; on failure, fall back to `cloudKitDatabase: .none` against the same schema/URL and log loudly. `fatalError` remains only if the fallback itself fails (a genuine corruption/bug).
- **Why not surface a UI:** v1 is silent; fallback keeps the app fully usable locally. A future sync-status surface can build on the same guard.
- **Previews/tests:** `TaskPreviewData.container()` stays `isStoredInMemoryOnly: true` + `.none`.

### D4: Refresh-on-remote-merge via `ModelContext.didSave`
ViewModel state is only recomputed via explicit `update()`, and `onChange(of:)` on `@Query` compares by `persistentModelID`, so property-only CloudKit merges do not recompute derived state. Add an app-wide observer: views `.onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave))` call their ViewModel's `update()`. This covers both local saves and remote merges uniformly.
- Also fix the one no-save mutation: `DetailViewModel.toggleCompletion` must call `save()`.

### D5: Data-gated backfill
`backfillSortOrdersIfNeeded` rewrites *every* task's `sortOrder` once per device behind a `UserDefaults` flag. On a second device this would clobber synced ordering. Gate on data instead: only assign sort orders to tasks with `sortOrder == nil`. The list backfill already checks `sortOrder == nil` and can be left, but should drop the flag-added short-circuit where data-driven checks already replace it.

### D6: Inbox dedupe via launch reconciler
"Inbox" is identified by name app-wide, and five call sites (`ContentView`, `CaptureBarViewModel`, `TimelineViewModel`, `Draft`, `TaskPreviewData`) can create one. Across devices this can yield duplicate Inbox lists. Add an idempotent, attribute-driven launch reconciler that merges tasks from duplicate `ReminderList(name: ReminderDefaults.defaultListName)` records into a single Inbox and deletes the extras. Runs every launch (cheap fetch + guard), not behind a `UserDefaults` flag.

### D7: Removed CloudKit rest is not reintroduced
The orphan `CloudKit.framework` file reference in `project.pbxproj` predates CloudKit removal; SwiftData mirroring does not require explicitly linking CloudKit (SwiftData imports it). Leave as-is this release unless a linker or runtime issue surfaces; do not add a `migrationPlan:` (AGENTS.md).

## Risks / Trade-offs

- **CloudKit production schema is additive-only** → All future model changes must add optional/default attributes and optional relationships; cannot delete types or change attribute types after promotion. Mitigation: track as a persistent requirement in `reminder-persistence-compatibility` spec; code-review checklist item.
- **Local store + first sync could hit schema-mirroring errors** → Watch console for 134060/134100 errors on first cloud launch; `D3` fallback prevents bricking. Verify on a seeded store in the simulator before release.
- **`tags` relationship without an explicit inverse** → CloudKit may reject an un-inferrable inverse. Mitigation: contingency `ReminderTag.tasks` back-reference in D2; verify during implementation.
- **Broad call-site ripple from optional arrays** → Mechanical but wide. Mitigation: computed helpers (D2), run the full unit/UI test suite after the V10 refactor before touching CloudKit wiring.
- **Conflicts (last-writer-wins)** → Acceptable for a personal task app; no conflict UI in v1 (Non-Goal). Sort-order `Int?` values may reorder after uncoordinated concurrent inserts — acceptable.
- **Single App ID sharing one container** → The `com.samson.wednesday` App ID must register the container; the retired `com.samsonsunny.app.task-flow` ID disappears from the portal entirely. A missed registration makes CloudKit fail at load, which `D3` turns into a silent local fallback. Mitigation: verify Debug and Release configs (same bundle ID) in verification.
- **Timeline manual order stays device-local** → Users' manual Today/Tomorrow/Overdue ordering won't sync. Documented limitation; follow-up option to promote ordering into model attributes.

## Migration Plan

1. **Developer portal (external, manual):** create container `iCloud.com.samson.wednesday`; add iCloud+CloudKit capability to both App IDs with it as default.
2. **Entitlements:** add container identifiers, default container, and iCloud services (CloudKit) to `TaskFlow.entitlements`.
3. **Schema V10** + call-site ripple; run full test suite (local, no CloudKit yet). Ship is safe at this point if verification stalls.
4. **Wire CloudKit** in `TaskFlowApp.swift` with the `D3` fallback; keep previews/tests local.
5. **Sync-aware fixes** (D4–D6) and the `DetailViewModel` save fix.
6. **Verification:** simulator pair sharing iCloud + one real device; fresh-install-to-cloud-pull, existing-store-to-cloud-upload, cross-device create/edit/delete/relationship merge, offline merge, ordering; promote dev schema to production; confirm on a `com.samson.wednesday` build.
7. **Rollback:** reverting entitlements + `cloudKitDatabase:` restores local-only behavior; schema V10 migrations are backward-compatible with V9 stores.

## Open Questions

- Whether CloudKit accepts the un-inferrable `tags` relationship as-is (resolved during implementation by the D2 contingency).
- Whether to explicitly link `CloudKit.framework` if the linker complains (low probability; Touch only if surfaced).