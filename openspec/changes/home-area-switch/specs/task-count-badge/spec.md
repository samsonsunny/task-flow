## Purpose

Define the app icon badge counts derived from due dates, including overdue and completed handling.

## MODIFIED Requirements

### Requirement: Badge shows overdue + today task count

The system SHALL display a badge on the app icon equal to the number of uncompleted tasks that are overdue or due today. The badge count SHALL be **global**: it SHALL aggregate across all areas and SHALL NOT be filtered by the selected area. Area scoping applies to on-screen surfaces only and SHALL NOT reduce the badge, because the badge is the app's only signal of outstanding work while the app is not running.

#### Scenario: Badge displays on app icon
- **WHEN** the app has uncompleted tasks that are overdue or due today
- **THEN** the app icon shows a badge with the count of those tasks
- **AND** the badge persists across app restarts

#### Scenario: Badge is not area-scoped
- **WHEN** Work has 3 tasks overdue or due today and Personal has 2
- **THEN** the badge SHALL read 5
- **AND** SHALL NOT read 3 or 2 regardless of the selected area

#### Scenario: Badge does not shrink when the other area is viewed
- **WHEN** the user switches to the area showing no outstanding work
- **THEN** the badge SHALL remain at its global count

#### Scenario: Badge updates after completing a task
- **WHEN** the user completes a task that was overdue or due today
- **THEN** the badge decrements by one after the 0.6s exit animation delay

#### Scenario: Badge updates when a task becomes overdue
- **WHEN** a task's due date passes (now > due date end of day)
- **THEN** the badge increments to include the newly overdue task

#### Scenario: Badge reaches zero
- **WHEN** all overdue and today-due tasks across every area are completed or rescheduled
- **THEN** the badge is removed (shows no number)

#### Scenario: Badge does not clear on app open
- **WHEN** the user opens the app
- **THEN** the badge remains visible at the current task count
- **AND** only the notification tray is cleared (per `clear-notifications-on-open`)

## ADDED Requirements

### Requirement: Area scoping never under-reports outstanding work

Wherever the app scopes an on-screen surface to the selected area, it SHALL disclose the non-selected area's outstanding due-today and overdue work rather than omitting it. Specifically: the pushed time screens SHALL render a non-dismissible cross-area nudge row reporting the other area's count with a one-tap switch; Home's summary block SHALL report only the selected area's counts while the global badge covers the rest.

#### Scenario: Scoped time screen discloses the other area
- **WHEN** the user views Today scoped to Work
- **AND** Personal has tasks due today or overdue
- **THEN** a nudge row SHALL state the other area's affected count
- **AND** the count SHALL NOT be included in the screen's task list

#### Scenario: Disclosure is actionable
- **WHEN** the nudge row is displayed
- **THEN** tapping it SHALL switch to the other area and stay on the same time segment

#### Scenario: No outstanding work in the other area
- **WHEN** the other area has no incomplete task due today or overdue
- **THEN** no nudge row SHALL be displayed
- **AND** the badge SHALL equal the selected area's outstanding count
