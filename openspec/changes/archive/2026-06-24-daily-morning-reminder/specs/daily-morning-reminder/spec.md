## ADDED Requirements

### Requirement: Settings view accessible from Today tab
The system SHALL provide a Settings view accessible via a gear icon button in the navigation toolbar of the Today tab.

#### Scenario: Gear icon visible in Today tab toolbar
- **WHEN** the user is on the Today tab
- **THEN** a gear icon button is visible in the top-right of the navigation toolbar

#### Scenario: Tapping gear icon opens Settings sheet
- **WHEN** the user taps the gear icon in the Today tab toolbar
- **THEN** a Settings sheet is presented modally

### Requirement: Settings sheet shows Daily Morning Reminder toggle
The system SHALL display a toggle switch labeled "Daily Morning Reminder" in the Settings sheet.

#### Scenario: Toggle visible in Settings
- **WHEN** the user opens the Settings sheet
- **THEN** a toggle labeled "Daily Morning Reminder" is visible

#### Scenario: Time picker visible only when toggle is on
- **WHEN** the Daily Morning Reminder toggle is ON
- **THEN** a time picker for setting the reminder time is visible below the toggle

#### Scenario: Time picker hidden when toggle is off
- **WHEN** the Daily Morning Reminder toggle is OFF
- **THEN** the time picker is hidden

#### Scenario: Done button dismisses Settings
- **WHEN** the user taps the Done button in Settings
- **THEN** the Settings sheet is dismissed

### Requirement: Toggle-on requests notification authorization
The system SHALL request notification authorization from the user when the Daily Morning Reminder toggle is turned ON for the first time.

#### Scenario: First toggle-on shows auth prompt
- **WHEN** the user turns ON the Daily Morning Reminder toggle and authorization has not been granted or denied
- **THEN** the system requests notification authorization

#### Scenario: Auth granted schedules the reminder
- **WHEN** the user turns ON the toggle and grants notification authorization
- **THEN** the system schedules the daily morning reminder notification

#### Scenario: Auth denied snaps toggle off
- **WHEN** the user turns ON the toggle and denies notification authorization
- **THEN** the toggle snaps back to OFF silently

### Requirement: System schedules recurring daily notification
The system SHALL schedule a local `UNNotificationRequest` with a `UNCalendarNotificationTrigger` that repeats daily at the configured time when the reminder is enabled.

#### Scenario: Daily notification scheduled at configured time
- **WHEN** the user has the Daily Morning Reminder enabled and configured to 7:00 AM
- **THEN** a daily notification is scheduled to fire at 7:00 AM each day

#### Scenario: Notification body shows static prompt
- **WHEN** the daily morning reminder notification fires
- **THEN** the notification displays a static prompt message and plays the default sound

### Requirement: Toggle-off cancels the notification
The system SHALL cancel the pending daily morning reminder notification when the toggle is turned OFF.

#### Scenario: Disabling toggle cancels notification
- **WHEN** the user turns OFF the Daily Morning Reminder toggle
- **THEN** any pending daily morning reminder notification is cancelled

### Requirement: Time change re-schedules the notification
The system SHALL cancel the existing daily notification and schedule a new one when the user changes the configured time while the toggle is ON.

#### Scenario: Changing time re-schedules notification
- **WHEN** the user changes the reminder time from 7:00 AM to 8:00 AM while the toggle is ON
- **THEN** the old notification is cancelled and a new one is scheduled for 8:00 AM

### Requirement: Reminder re-scheduled on app launch if missing
The system SHALL check that the daily morning reminder notification exists on app launch and re-schedule it if missing when the preference is enabled.

#### Scenario: App launch re-schedules orphaned daily reminder
- **WHEN** the app launches and the Daily Morning Reminder is enabled but no matching pending notification exists
- **THEN** the system schedules the daily morning reminder notification
