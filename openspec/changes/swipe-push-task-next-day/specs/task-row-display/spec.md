## MODIFIED Requirements

### Requirement: Task row swipe actions adapt to segment context
In Today, Tomorrow, and Overdue segment views, the task row SHALL display a single trailing swipe action that reschedules the task to the next day. The swipe SHALL allow full swipe activation. The existing destructive delete swipe action SHALL NOT be shown in these segment views (delete remains available via context menu and bulk selection). In all other views (Upcoming, Later, List Detail), swipe actions SHALL remain unchanged.

#### Scenario: Today view shows reschedule swipe
- **WHEN** a task row is rendered in the Today view
- **THEN** a trailing swipe action is configured to reschedule the task to the next day
- **AND** the swipe action allows full swipe activation
- **AND** no delete swipe action is shown

#### Scenario: Tomorrow view shows reschedule swipe
- **WHEN** a task row is rendered in the Tomorrow view
- **THEN** a trailing swipe action is configured to reschedule the task to the next day
- **AND** the swipe action allows full swipe activation
- **AND** no delete swipe action is shown

#### Scenario: Overdue section in Today shows reschedule swipe
- **WHEN** a task row is rendered in the Overdue section of the Today view
- **THEN** a trailing swipe action is configured to reschedule the task to the next day
- **AND** the swipe action allows full swipe activation
- **AND** no delete swipe action is shown

#### Scenario: Upcoming view retains delete swipe
- **WHEN** a task row is rendered in the Upcoming view
- **THEN** the existing trailing swipe actions are unchanged (delete remains available)

#### Scenario: List detail view retains delete swipe
- **WHEN** a task row is rendered in a List Detail view
- **THEN** the existing trailing swipe actions are unchanged (delete remains available)
