## Why

TaskFlow is a task manager, but has no habit loop to bring users back daily. Users set tasks and forget about them. A morning notification with a single tap-to-open action creates a daily check-in ritual, increasing engagement and ensuring users actually see what they planned.

## What Changes

- Add a **Settings view** accessible from a gear icon in the Today tab toolbar
- Add a **Daily Morning Reminder** toggle + time picker in Settings
- Schedule a recurring local notification at the user's chosen time when enabled
- Cancel the notification when disabled or time is changed
- Re-schedule the daily reminder on app launch if missing (existing pattern)

## Capabilities

### New Capabilities
- `daily-morning-reminder`: Recurring daily notification with configurable time, toggle on/off, and Settings UI entry point

### Modified Capabilities

None. The existing per-task notification system (`task-notifications`) is unchanged.

## Impact

- `TaskFlow/Features/Reminders/TodayTabView.swift` — add toolbar gear icon, present Settings sheet
- `TaskFlow/Features/Reminders/SettingsView.swift` — new view: toggle + time picker + Done button
- `TaskFlow/Utilities/NotificationService.swift` — add `scheduleDailyReminder()`, `cancelDailyReminder()`, refactor shared auth logic
- `@AppStorage` keys for `dailyReminderEnabled` (Bool) and `dailyReminderHour`/`dailyReminderMinute` (Int)
