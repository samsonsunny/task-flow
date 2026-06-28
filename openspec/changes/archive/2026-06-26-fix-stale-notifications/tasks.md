## 1. Migration flag and cleanup

- [x] 1.1 Add a `UserDefaults` key constant `"didPerformNotificationMigration"` to `NotificationService` (alongside `DailyReminderKeys`)
- [x] 1.2 Add a private computed property `hasRunMigration` that reads the flag from `defaults`
- [x] 1.3 Add a private method `performMigration()` that calls `center.removeAllPendingNotificationRequests()` and `center.removeAllDeliveredNotifications()`, then sets the flag to `true`
- [x] 1.4 Guard the top of `reschedulePendingOnLaunch()`: if `!hasRunMigration`, call `performMigration()` before proceeding to the existing fetch/schedule logic

## 2. Verify

- [x] 2.1 Build and run: confirm migration runs once on first launch and existing valid notifications are re-scheduled
- [x] 2.2 Build and run again: confirm migration does NOT run on second launch
- [x] 2.3 Verify that stale notifications (deleted tasks, date-only tasks, past-due tasks) are gone from the system notification queue
- [x] 2.4 Verify the daily morning reminder is re-scheduled if the user had it enabled
