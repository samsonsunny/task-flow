## Why

When a local notification fires (task reminder or daily reminder), it stays in the system Notification Center indefinitely. If the user opens the app, taps the notification, and closes it, stale notifications remain in the tray on subsequent opens. This is clutter — once the user has opened the app, delivered notifications no longer serve a purpose.

## What Changes

- `TaskFlowApp.swift` gains a `scenePhase` observer
- On every transition to `.active`, all delivered notifications are cleared from the system tray
- No changes to notification scheduling, badge management, or authorization

## Capabilities

### New Capabilities
- `clear-notifications-on-open`: Clear delivered notifications when the app becomes active

### Modified Capabilities
*(none)*

## Impact

- `TaskFlowApp.swift`: +3 lines (scenePhase environment + onChange handler)
- No new imports — `UNUserNotificationCenter` already imported transitively via `NotificationService.swift`
