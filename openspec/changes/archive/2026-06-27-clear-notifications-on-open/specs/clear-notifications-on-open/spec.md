## ADDED Requirements

### Requirement: Clear delivered notifications on app activation
The system SHALL remove all delivered notifications from the system Notification Center when the app becomes active.

#### Scenario: App becomes active by any path
- **WHEN** the app transitions to the `.active` scene phase (cold launch, foreground from background, return from another app)
- **THEN** all delivered notifications are removed via `UNUserNotificationCenter.current().removeAllDeliveredNotifications()`

#### Scenario: Notifications still fire normally
- **WHEN** a task reminder or daily reminder fires while the app is not active
- **THEN** the notification appears in the system Notification Center as usual
- **AND** the notification is only removed when the user next opens the app
