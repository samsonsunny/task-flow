## Why

Users who upgraded from older builds have stale notifications in the system queue: notifications for deleted tasks, and notifications for date-only tasks (midnight/12AM) that should never have fired. These cannot be removed without a migration because the current `reschedulePendingOnLaunch` only adds missing notifications — it never cleans up orphaned ones.

## What Changes

- Add a one-time migration that clears all pending and delivered notifications from the system queue on first launch after upgrade
- Re-schedule only valid notifications (future-dated, non-completed tasks with `safeHasTime == true` and the daily morning reminder if enabled)
- Set a `UserDefaults` flag so the migration runs exactly once

## Capabilities

### New Capabilities
- `notification-migration`: One-time cleanup of stale/orphaned notifications from the system queue on app upgrade

### Modified Capabilities

<!-- No existing specs change behavior — this is an internal migration, not a user-facing capability change -->

## Impact

- `NotificationService.swift`: Add migration logic called on app launch
- `TaskFlowApp.swift` or `ContentView.swift`: Call the migration from the existing launch path
- Test: Verify stale notifications are cleared and valid ones are re-scheduled on first launch after update
