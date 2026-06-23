## ADDED Requirements

### Requirement: Task row persists visually after completion
The system SHALL keep a completed task visible in the list for 0.6 seconds after the completion action, showing the completed visual state (strikethrough, dimmed opacity).

#### Scenario: Task completes with visual delay
- **WHEN** the user taps the completion circle on a task
- **THEN** the task is immediately marked complete in the data model
- **AND** the task row remains visible with completed styling for 0.6 seconds
- **AND** after 0.6 seconds, the row exits with a fade + scale transition

#### Scenario: Data persisted immediately on tap
- **WHEN** the user taps the completion circle
- **THEN** `isCompleted` is set to `true` and `completionDate` is set to the current time immediately (not after the 0.6s delay)

#### Scenario: Notification cancelled immediately on tap
- **WHEN** the user taps the completion circle on a task with a pending notification
- **THEN** the pending notification is cancelled immediately, not after the 0.6s delay

### Requirement: No exit animation on non-completion paths
The system SHALL NOT play the deferred exit animation when a task is removed from the list for non-completion reasons.

#### Scenario: Delete does not animate
- **WHEN** the user deletes a task
- **THEN** the task is removed immediately without the 0.6s delay or exit transition
