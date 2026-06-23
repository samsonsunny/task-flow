## ADDED Requirements

### Requirement: Task completion plays medium haptic feedback
The system SHALL play a medium-impact haptic when the user completes a task by tapping the circle in `TaskRowView`.

#### Scenario: Completing a task triggers haptic
- **WHEN** the user taps the completion circle on a task
- **THEN** the system plays a `UIImpactFeedbackGenerator(style: .medium)` haptic before the visual completion animation

#### Scenario: Un-completing a task does not trigger haptic
- **WHEN** the user taps the un-complete button in `CompletedView`
- **THEN** the system does NOT play any haptic feedback
