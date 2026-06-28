## MODIFIED Requirements

### Requirement: Task row persists visually after completion
The system SHALL keep a completed task visible in the list for 1.5 seconds after the completion action, showing the completed visual state (strikethrough, dimmed opacity) **at its original sorted position** in the list.

The task SHALL NOT change position during the 1.5-second grace period. The row SHALL render with:
- `.strikethrough(true)` on the title text, animated with 0.18s easeInOut
- Text color shifted to `textSecondary`, animated with 0.18s easeInOut
- Text opacity reduced to 0.82, animated with 0.18s easeInOut
- Completion circle filled with `primaryAction` color and checkmark visible

#### Scenario: Task completes with visual delay
- **WHEN** the user taps the completion circle on a task
- **THEN** the task is immediately marked complete in the data model
- **AND** the task row remains visible **in its current sorted position** with completed styling for 1.5 seconds
- **AND** after 1.5 seconds, the row exits with a fade + scale transition

#### Scenario: Data persisted immediately on tap
- **WHEN** the user taps the completion circle
- **THEN** `isCompleted` is set to `true` and `completionDate` is set to the current time immediately (not after the 1.5s delay)

#### Scenario: Notification cancelled immediately on tap
- **WHEN** the user taps the completion circle on a task with a pending notification
- **THEN** the pending notification is cancelled immediately, not after the 1.5s delay

### Requirement: No exit animation on non-completion paths
The system SHALL NOT play the deferred exit animation when a task is removed from the list for non-completion reasons.

#### Scenario: Delete does not animate
- **WHEN** the user deletes a task
- **THEN** the task is removed immediately without the 1.5s delay or exit transition
