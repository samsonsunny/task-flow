## Context

The `ReminderDraft` struct (transient, UI-only) already has a `hasTime` field that tracks whether the user enabled the time toggle. But this field is never persisted to `TaskItem`. Once saved, there's no way to distinguish "user set date only" from "user set date at midnight." The `NotificationService` has no choice but to schedule a notification for any future `dueDate` regardless of user intent.

The existing spec in `task-notifications` already says "Task saved without time skips scheduling" — and `ReminderEditorView.saveReminder()` correctly does this. But `reschedulePendingOnLaunch` and `CompletedView.uncomplete()` bypass this guard because they work from the persisted model, which has no `hasTime` flag.

## Goals / Non-Goals

**Goals:**
- Persist `hasTime` on `TaskItem` so notification scheduling can reliably check user intent
- `schedule(for:)` never fires a notification for a date-only reminder
- `reschedulePendingOnLaunch` only reschedules tasks that had time enabled
- `CompletedView.uncomplete()` respects `hasTime`
- All save paths (`ReminderDraftMapper`, schedule sheets) persist `hasTime`
- Existing date-only reminders in user data are treated correctly (no midnight notifications)

**Non-Goals:**
- Changing the UI behavior of the date/time toggles
- Changing how `startOfDay(for:)` normalization works (midnight is still the storage convention for date-only)
- Adding a general-purpose audit of all notification scheduling paths beyond the scope of this bug

## Decisions

### Decision: Persist `hasTime` on `TaskItem` rather than heuristically checking for midnight

**Chosen:** Add an explicit `Bool?` field `hasTime` to `TaskItem`.

**Alternatives considered:**
- *Heuristic*: Check if `dueDate` components are all midnight — fragile, breaks if any future feature intentionally uses midnight.
- *Store-only approach*: Only fix `reschedulePendingOnLaunch` to not leak — doesn't fix `CompletedView` or any future caller of `schedule(for:)`.
- *Remove `startOfDay` normalization*: Would change existing behavior where date-only reminders show correctly in UI segments.

**Rationale:** An explicit persisted flag is the only reliable way to preserve user intent across app restarts. It's a single boolean, lightweight, and the migration is additive-only (no data loss risk).

### Decision: `hasTime` is optional (`Bool?`) with heuristic fallback for legacy tasks

Existing saved tasks won't have `hasTime`. For `nil` values, the system uses a time-component heuristic: if `dueDate` has non-midnight time (hour != 0 or minute != 0), treat as `hasTime == true`; otherwise treat as `false`. This preserves notifications for legacy tasks that were saved WITH a time (common case) while correctly suppressing them for legacy date-only tasks.

### Decision: Keep `startOfDay` normalization for date-only

When `hasTime` is false, `dueDate` is still normalized to midnight via `startOfDay(for:)`. This keeps UI segment filtering consistent (the "Today" segment checks `startOfDay` equality). The fix is purely in the notification scheduling gate.

### Decision: Add `hasTime` to schema V4 (lightweight migration)

A new `TaskFlowSchemaV4` with the `hasTime` field added to `TaskItem`. The migration plan gets a new lightweight stage from V3 to V4.

## Risks / Trade-offs

- **[Existing date-only reminders]** Tasks saved before this change have `hasTime = nil`. The heuristic (midnight check) correctly identifies them as date-only and suppresses notifications. If a user *wanted* a notification for a date-only reminder (unlikely — that was the bug), they re-save with time enabled. → Acceptable.
- **[Legacy time-enabled + midnight edge case]** If a user previously set a reminder with time enabled to exactly 12:00 AM and saved it, the heuristic treats it as date-only and suppresses the notification. → Extremely unlikely scenario; acceptable trade-off.

- **[Migration risk]** Adding a field to a `@Model` class is generally safe with lightweight migration. But if the schema versioning or migration plan is already complex, a new stage could conflict. → The existing migration plan (`TaskFlowMigrationPlan`) already has 3 schemas with 2 lightweight stages. Adding a third stage (`V3→V4`) is straightforward and follows the established pattern.

- **[merge conflicts with other changes in flight]** If another change also touches `TaskItem` schema, migration stage ordering could conflict. → Review other active changes before merging.

- **[Edge case: user intentionally sets 00:00 via time picker]** If a user explicitly toggles time on and sets it to 12:00 AM, `hasTime = true` and a notification fires at midnight. This is correct — they intentionally set that time.
