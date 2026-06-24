## 1. Preference Storage & Notification Service

- [x] 1.1 Add `@AppStorage` keys for `dailyReminderEnabled` (Bool, default false), `dailyReminderHour` (Int, default 7), `dailyReminderMinute` (Int, default 0)
- [x] 1.2 Add `scheduleDailyReminder(atHour:hour:minute:)` to `NotificationService` — creates a `UNCalendarNotificationTrigger` with `repeats: true`, identifier `"daily-morning-reminder"`, static body text, requests auth if needed
- [x] 1.3 Add `cancelDailyReminder()` to `NotificationService` — cancels pending request and removes delivered notification with identifier `"daily-morning-reminder"`
- [x] 1.4 Extend `reschedulePendingOnLaunch` to check if the daily reminder notification is pending when `dailyReminderEnabled` is true, and re-schedule if missing

## 2. Settings View

- [x] 2.1 Create `SettingsView.swift` with a toggle "Daily Morning Reminder" bound to `dailyReminderEnabled`
- [x] 2.2 Add conditional `DatePicker` (hourAndMinute) shown only when toggle is on, bound to computed time from hour/minute preferences
- [x] 2.3 Wire toggle-on to call `scheduleDailyReminder` (handles auth request) and toggle-off to call `cancelDailyReminder`
- [x] 2.4 Wire time picker change to call `cancelDailyReminder` + `scheduleDailyReminder`
- [x] 2.5 Add Done button in toolbar that dismisses the sheet

## 3. Today Tab Toolbar Integration

- [x] 3.1 Add a gear icon (`Image(systemName: "gearshape")`) to the trailing toolbar of `TodayTabView`'s `NavigationStack`
- [x] 3.2 Add `@State private var showSettings = false` and wire the gear button to present `SettingsView` as a sheet

## 4. Verification

- [x] 4.1 Build and run the app on simulator/device
- [ ] 4.2 Verify gear icon appears in Today tab toolbar
- [ ] 4.3 Verify Settings sheet opens, toggle works, time picker appears/hides, Done dismisses
- [ ] 4.4 Verify notification is scheduled at configured time
- [ ] 4.5 Verify toggling off cancels the notification
