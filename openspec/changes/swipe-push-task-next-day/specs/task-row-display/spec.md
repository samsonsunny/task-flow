## MODIFIED Requirements

### Requirement: Task row swipe actions adapt to segment context
In Today, Tomorrow, and Overdue segment views, the task row SHALL display a leading (left) swipe action that reschedules the task to the next day, and a trailing (right) swipe action for delete. The reschedule swipe SHALL allow full swipe activation. In all other views (Upcoming, Later, List Detail), only the trailing delete swipe action is shown.

#### Scenario: Today view shows leading reschedule and trailing delete
- **WHEN** a task row is rendered in the Today view
- **THEN** a leading swipe action reschedules the task to the next day
- **AND** a trailing swipe action deletes the task

#### Scenario: Tomorrow view shows leading reschedule and trailing delete
- **WHEN** a task row is rendered in the Tomorrow view
- **THEN** a leading swipe action reschedules the task to the next day
- **AND** a trailing swipe action deletes the task

#### Scenario: Overdue section in Today shows leading reschedule and trailing delete
- **WHEN** a task row is rendered in the Overdue section of the Today view
- **THEN** a leading swipe action reschedules the task to the next day
- **AND** a trailing swipe action deletes the task

#### Scenario: Upcoming view retains delete swipe only
- **WHEN** a task row is rendered in the Upcoming view
- **THEN** only the trailing delete swipe action is shown

#### Scenario: List detail view retains delete swipe only
- **WHEN** a task row is rendered in a List Detail view
- **THEN** only the trailing delete swipe action is shown
