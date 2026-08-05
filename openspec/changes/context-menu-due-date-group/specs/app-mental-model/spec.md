## ADDED Requirements

### Requirement: Due date context menu actions
The task context menu SHALL present scheduling actions as flat top-level items (Today, Tomorrow, This Weekend, and No Date when dated) plus a "More" submenu (Next Week, Next Month, Custom…). Presets that match the task's current due date SHALL be omitted. "No Date" clears a task's due date, returning it to Later-only visibility.

#### Scenario: Menu aligns with the two-axis model
- **WHEN** the user opens a task's context menu in a time tab
- **THEN** the flat due date presets and "More" submenu SHALL be present
- **AND** tapping "No Date" SHALL clear the due date
- **AND** the task SHALL disappear from the time tab and appear only in its list

#### Scenario: Later label is removed
- **WHEN** the user opens a task's context menu
- **THEN** no action SHALL be labeled "Later"
- **AND** the due-date clearing action SHALL be labeled "No Date"
