## Context

TaskFlow has per-task notifications that fire at a task's dueDate when a time is set, but no recurring daily notification to bring users back. A daily morning reminder establishes a check-in habit. The existing `NotificationService` singleton and `UNUserNotificationCenter` infrastructure can be extended.

The app has no Settings screen today. This introduces one, accessible from the Today tab toolbar.

## Goals / Non-Goals

**Goals:**
- A Settings sheet accessible from a gear icon in the Today tab toolbar
- A toggle to enable/disable a daily morning notification
- A time picker for the notification time (only visible when enabled)
- A recurring local notification that fires daily at the chosen time
- Persist the preference across launches via `@AppStorage`
- Re-schedule the daily notification on app launch if missing (matching existing pattern)

**Non-Goals:**
- No dynamic notification content (no service extension, no task summary in the notification)
- No multiple reminders per day
- No calendar integration or smart scheduling
- No in-app notification history
- No SwiftData model for settings (premature — single preference pair fits `@AppStorage`)

## Decisions

1. **`@AppStorage` over SwiftData for preferences** — A single boolean + two integers (hour/minute) do not warrant a model class, schema migration, or `@Query`. `@AppStorage` is zero-setup and persists via `UserDefaults`. If the settings surface grows (e.g., theme, default list, notification sound), migrate to a SwiftData `AppPreference` model later.

2. **Static notification body** — The notification reads "☀️ Good morning — your day is waiting" or similar. No service extension or dynamic content. Rationale: the goal is to get the user to open the app, not to display task data in the notification. This keeps complexity near-zero.

3. **`UNCalendarNotificationTrigger` with `repeats: true`** — A single request with `.hour`/`.minute` components and `repeats: true`. No need to re-schedule daily. Identifier: `"daily-morning-reminder"`. When the toggle is turned off or the time changes, cancel by that identifier and optionally re-schedule.

4. **Re-schedule on app launch** — Extend the existing `reschedulePendingOnLaunch` in `NotificationService` to also check if the daily reminder notification is pending when the preference is enabled. This handles edge cases where iOS may drop pending notifications (rare but possible).

5. **Settings as a `.sheet` from Today tab toolbar** — No separate navigation stack or tab. A simple modal sheet with a Done button. Consistent with how the rest of the app presents modals.

6. **Auth request on first toggle-on** — When the user flips the switch to on, call `requestAuthorizationIfNeeded()`. If denied, snap the toggle back to off silently. No alert to the user about denial.

## Risks / Trade-offs

- **[Low] Toggle-on triggers auth prompt immediately** — Could be jarring if user isn't expecting it. Mitigation: auth prompt is a standard iOS system dialog, users are familiar with it. The toggle flips back silently on denial.
- **[Low] `repeats: true` notifications cannot be updated without replacement** — If user changes time, we must cancel and re-schedule. Handled by the existing `cancel(identifier:)` pattern.
- **[Low] iOS may throttle background re-scheduling** — The re-schedule-on-launch pattern handles this. On app launch (user-initiated), we always reconcile.
