## ADDED Requirements

### Requirement: Due date context menu actions
The task context menu SHALL present scheduling actions inside a single "Deadline" submenu (None, a divider, then Today, Tomorrow, This Weekend, Next Week, Custom…). The item matching the task's current due date SHALL be marked with a checkmark (None when undated, the matching preset, or Custom… for any other date). "None" clears a task's due date, returning it to Later-only visibility.

#### Scenario: Menu aligns with the two-axis model
- **WHEN** the user opens a task's context menu in a time tab
- **THEN** a "Deadline" submenu SHALL be present
- **AND** tapping "None" SHALL clear the due date
- **AND** the task SHALL disappear from the time tab and appear only in its list

#### Scenario: Later label is removed
- **WHEN** the user opens a task's context menu
- **THEN** no action SHALL be labeled "Later"
- **AND** the due-date clearing action SHALL be labeled "None"
