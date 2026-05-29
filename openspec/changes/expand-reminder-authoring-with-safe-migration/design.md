## Context

TaskFlow currently persists reminders through a single `TaskItem` SwiftData model with a narrow field set: title, description, due date, completion state, flag state, and timestamps. The requested reminder authoring behavior introduces materially broader data requirements, including notes, URL, list assignment, tags, priority, contact assignment, image attachment, and richer save/discard rules. Existing saved reminders already live on user devices, so the data model cannot be reset or replaced with a destructive rewrite.

This change crosses persistence, authoring UI, validation logic, previews, and tests. It also needs to stay aligned with the external scheduling rules so reminder creation and editing do not diverge once schedule fields are added.

## Goals / Non-Goals

**Goals:**
- Expand reminder persistence so the product can store the new authoring fields safely.
- Preserve all existing reminders and current values during migration.
- Define a create/edit architecture that shares validation, dirty-state tracking, and save mapping.
- Keep migration additive so later reminder requirements can be layered on without another disruptive rewrite.

**Non-Goals:**
- Implement notification delivery, contact permission prompts, or image binary storage internals beyond what authoring needs to reference them.
- Redesign reminder browsing, task bucketing, or smart-list behavior outside what new fields require.
- Migrate legacy records into a brand-new top-level store if an additive evolution of the current model is sufficient.

## Decisions

### Decision: Evolve the existing persisted reminder root model instead of replacing it
The safest migration path is to keep `TaskItem` as the persisted root entity for this phase and add new optional properties and relationships around it. Existing reminders already map naturally to a subset of the richer authoring model, so an additive schema evolution avoids lossy transforms and reduces rollout risk.

Alternative considered:
- Introduce a new `Reminder` root entity and bulk-convert all `TaskItem` rows. Rejected because it creates higher migration risk, forces one-time data rewriting, and complicates rollback.

### Decision: Use versioned SwiftData schemas with explicit migration handling
The reminder model should move under a versioned schema/migration plan rather than relying on ad hoc field additions. New properties should default safely for migrated rows: empty notes/URL, no tags, priority `none`, unresolved list assignment until mapped to the default `Reminders` list, and no attachment/contact payload unless present.

Alternative considered:
- Keep a single unversioned model and depend on implicit lightweight evolution. Rejected because the field count is increasing and future reminder requirements will likely need deterministic migrations.

### Decision: Separate authoring draft state from persisted model state
Create and edit flows should use a dedicated draft/view-model layer that tracks transient values, dirty state, validation state, and discard behavior before save. Persisted `TaskItem` rows should only be updated when the user explicitly saves.

Alternative considered:
- Bind forms directly to SwiftData entities. Rejected because it makes discard confirmation unreliable and leaks partially edited state into persisted records.

### Decision: Model complex reminder metadata as optional companions when needed
Primitive fields such as notes, URL, priority, and list identifier can live directly on the reminder root. More complex data such as tags, contact assignment, recurrence, and attachments should use either lightweight related entities or codable value objects so the core reminder record remains stable while richer sub-features evolve independently.

Alternative considered:
- Flatten every field into the root model. Rejected because attachments, recurrence, and tag relationships are likely to grow and would make future schema changes harder.

### Decision: Preserve legacy semantics through explicit field mapping
Current `taskTitle`, `taskDescription`, `dueDate`, `isFlagged`, `isCompleted`, and `completionDate` values must remain intact. Legacy `taskDescription` should map forward as reminder notes, existing due dates should continue to represent the reminder's scheduled date, and missing new fields must resolve to safe defaults without requiring user action after migration.

Alternative considered:
- Leave legacy fields untouched and layer new duplicate fields beside them. Rejected because it invites divergence and unclear source-of-truth rules.

## Risks / Trade-offs

- [Migration bugs could hide or null out user reminders] → Use a versioned schema, additive defaults, and migration tests built from representative legacy fixtures.
- [Direct entity editing could cause accidental saves] → Route create/edit through an isolated draft model with explicit save/apply mapping.
- [Future requirements may outgrow the expanded `TaskItem` shape] → Keep the root reminder entity stable and move richer concerns into companion models or codable payloads.
- [External reminder specs may still evolve] → Treat this design as the safe persistence foundation and keep schedule, contact, and attachment integrations modular.

## Migration Plan

1. Introduce a versioned SwiftData schema for the current reminder entity.
2. Add new optional fields and companion structures in the next schema version with safe defaults for migrated rows.
3. Provide explicit mapping rules for legacy fields, especially `taskDescription` to reminder notes and existing scheduling/completion values.
4. Build migration fixtures from current on-device-style data and verify reminders remain queryable after upgrade.
5. Ship create/edit UI against the draft layer once the migrated model is stable.
6. If rollback is required before release, retain the legacy field surface and avoid destructive one-way transforms so existing data remains readable.

## Open Questions

- Image attachment persistence format is still open: file reference, Photos identifier, or serialized app-managed blob metadata.
- Contact assignment may require a stable lightweight identifier strategy if device contacts change or permissions are later revoked.
- The malformed URL validation branch called out in the source authoring spec still needs a product decision before implementation.
