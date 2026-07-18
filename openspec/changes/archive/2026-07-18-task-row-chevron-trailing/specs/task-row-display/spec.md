## MODIFIED Requirements

### Requirement: Task row shows collapse/expand control for parents
When a task has subtasks, the task row SHALL display a collapse/expand control (chevron) at the trailing edge, after the title content, vertically centered within the row. The chevron SHALL point down when expanded and right when collapsed.

#### Scenario: Chevron appears on parent task
- **WHEN** a task has one or more subtasks
- **THEN** a collapse/expand chevron SHALL appear at the trailing edge of the row, after the title
- **AND** the chevron SHALL be vertically centered within the row
- **AND** the chevron SHALL point downward when the subtask list is expanded
- **AND** the chevron SHALL point rightward when the subtask list is collapsed

#### Scenario: No chevron on leaf task
- **WHEN** a task has no subtasks
- **THEN** no chevron SHALL be displayed

#### Scenario: Multi-line title does not displace chevron
- **WHEN** a task has a long title that wraps to multiple lines
- **THEN** the chevron SHALL remain vertically centered at the trailing edge of the row
- **AND** the chevron SHALL NOT shift to the top or bottom of the row

## ADDED Requirements

### Requirement: Task row buttons have expanded hit targets
The completion circle and chevron buttons in `TaskRowView` SHALL have a minimum tappable area of 44×44pt, while maintaining their visual size at 20×20pt.

#### Scenario: Completion button has expanded hit target
- **WHEN** a user taps near the completion circle (within 44×44pt area centered on the 20×20pt visual)
- **THEN** the completion toggle action SHALL trigger

#### Scenario: Chevron button has expanded hit target
- **WHEN** a user taps near the chevron (within 44×44pt area centered on the 20×20pt visual)
- **THEN** the collapse/expand action SHALL trigger

#### Scenario: Hit targets do not overlap
- **WHEN** the completion circle and chevron are both visible on a parent task
- **THEN** their 44×44pt hit target areas SHALL NOT overlap
- **AND** tapping the correct control SHALL reliably trigger the intended action
