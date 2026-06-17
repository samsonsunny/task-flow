# reminder-context-menu-delete Specification

## Purpose
Define the reminder context menu delete action so users can remove reminders from row context menus across segment and list detail views.
## Requirements
### Requirement: Delete reminder from context menu

The system SHALL provide a Delete action in the reminder context menu that removes the reminder from the data store.

#### Scenario: Delete from ReminderSegmentDetailView context menu
- **WHEN** the user long-presses a reminder row in any segment view (Today, Tomorrow, Upcoming, Later, Overdue)
- **THEN** the context menu SHALL include a "Delete" button with a trash icon and destructive styling
- **WHEN** the user taps "Delete"
- **THEN** the reminder SHALL be immediately deleted from SwiftData and removed from the list

#### Scenario: Delete from ListDetailView context menu
- **WHEN** the user long-presses a reminder row in a list detail view
- **THEN** the context menu SHALL include a "Delete" button
- **WHEN** the user taps "Delete"
- **THEN** the reminder SHALL be immediately deleted from SwiftData and removed from the list

#### Scenario: Delete button uses destructive role
- **WHEN** the context menu displays
- **THEN** the Delete button SHALL use `.role(.destructive)` with red styling

#### Scenario: Delete is available regardless of reminder state
- **WHEN** the context menu displays for any reminder (completed or incomplete, with or without due date)
- **THEN** the Delete button SHALL always be present
