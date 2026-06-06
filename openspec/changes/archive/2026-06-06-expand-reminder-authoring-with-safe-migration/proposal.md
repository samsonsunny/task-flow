## Why

TaskFlow's current reminder model supports only a narrow subset of the behavior defined in the new reminder authoring requirements. Expanding authoring now is necessary to add richer reminder metadata without breaking or silently rewriting reminders that users have already saved.

## What Changes

- Expand reminder authoring to support title, notes, URL, list assignment, tags, flag, priority, contact assignment, image attachment, and optional schedule-related inputs.
- Define create and edit flow behavior for save enablement, discard confirmation, default list assignment, and empty-state validation.
- Introduce a forward-compatible reminder persistence shape that can absorb the new authoring fields incrementally.
- Add a safe data migration strategy so existing persisted reminders continue to load, retain current values, and receive sensible defaults for newly introduced fields.
- Clarify how legacy `TaskItem`-backed reminders map into the richer authoring model during rollout and future schema revisions.

## Capabilities

### New Capabilities
- `reminder-authoring`: Create and edit reminders with richer content fields, validation, save/discard behavior, and default authoring rules.
- `reminder-persistence-compatibility`: Preserve existing saved reminders while expanding the reminder data model and introducing migration-safe defaults for new fields.

### Modified Capabilities

## Impact

- Affected code: `TaskFlow/Models`, reminder feature views, capture/edit flows, preview fixtures, and test coverage.
- Persistence: SwiftData schema/model evolution, migration planning, and compatibility handling for existing on-device reminders.
- UI behavior: new authoring screens, richer form state, save/discard handling, and edit-mode parity with create flow.
- Dependencies: authoring behavior must remain aligned with the scheduling rules described in `/Users/sam/Desktop/Specs/specs/01-reminders/scheduling.md`.
