## Context

The app's current notification scheduling (`schedule(for:)`) correctly guards against creating notifications for tasks without explicit times via `safeHasTime`. However, the launch-time reconciliation (`reschedulePendingOnLaunch`) is additive-only — it fills gaps but never removes orphaned notifications. This means:

- Notifications for tasks deleted before the cancel logic was bulletproof persist indefinitely
- Notifications from builds before `hasTime` gating existed remain in the system queue
- The system queue accumulates stale entries that users see despite the app believing they're clean

A one-time migration on first launch after this update will reset the system to a clean state.

## Goals / Non-Goals

**Goals:**
- Remove all stale notification requests from the system on first launch after upgrade
- Re-schedule only notifications that pass the current validity checks (future date, non-completed, `safeHasTime == true`)
- Preserve the daily morning reminder if the user has it enabled
- Run exactly once — subsequent launches use the existing additive reconciliation

**Non-Goals:**
- Changing the ongoing notification scheduling logic (`schedule()`, `cancel()`, `reschedulePendingOnLaunch`)
- Adding UI for notification management
- Changing how `safeHasTime` works
- Making this a periodic cleanup (one-time only)

## Decisions

**Decision: Full wipe (`removeAllPendingNotificationRequests`) over selective reconciliation**

Selective reconciliation (querying pending IDs, computing which are orphaned, removing only those) is more precise but:
- Requires maintaining a valid-set computation that mirrors `schedule()`'s guard conditions — a maintenance burden
- The full wipe is a single call, adds ~50ms on first launch, and is guaranteed correct
- After the wipe, the existing `reschedulePendingOnLaunch` logic correctly re-adds only valid notifications

Approach: Call `center.removeAllPendingNotificationRequests()` and `center.removeAllDeliveredNotifications()` before the existing reschedule logic, guarded by a `UserDefaults` flag.

**Decision: `UserDefaults` flag over bundle version comparison**

A simple boolean flag (`"didPerformNotificationMigration"`) is simpler and more robust than parsing `CFBundleVersion`. The flag is set after the migration completes and checked on each launch. If a user reinstalls the app, the flag resets naturally (UserDefaults are wiped on uninstall), which is correct behavior.

**Decision: Migration runs in `reschedulePendingOnLaunch` before existing logic**

No new entry point needed. The migration check lives at the top of `reschedulePendingOnLaunch`, which already runs on `ContentView.onAppear`. This keeps the launch path simple.

### Flow

```
ContentView.onAppear
  │
  └── NotificationService.reschedulePendingOnLaunch()
        │
        ├── if !didPerformMigration:
        │     ├── removeAllPendingNotificationRequests()
        │     ├── removeAllDeliveredNotifications()
        │     └── didPerformMigration = true
        │
        └── [existing logic: fetch active tasks, filter, schedule missing]
```

## Risks / Trade-offs

- **Momentary flicker of valid notifications**: If a valid notification was pending and the user opens the app right when it was about to fire, the wipe + reschedule might cause a brief visual inconsistency. Likelihood is extremely low. Mitigation: the migration runs synchronously (on the actor) before any async work, so the window is negligible.

- **Reset notification delivery tracking**: iOS tracks whether a notification has been delivered. Wiping delivered notifications removes that history. Not a practical concern — the migration runs only once.

- **Daily morning reminder re-fire if it already fired today**: After the wipe, if the daily reminder already fired earlier today, it'll be re-scheduled for tomorrow (repeating trigger). Correct behavior — no double-fire risk.
