## ADDED Requirements

### Requirement: Editor supports subtask creation
The `ReminderEditorView` SHALL provide a "Add Subtask" control that allows creating subtasks for the task being edited. Subtask creation SHALL be available in both new-task and edit-task modes.

#### Scenario: Add subtask in editor
- **WHEN** user opens `ReminderEditorView` for a task
- **AND** taps "Add Subtask"
- **THEN** a text field SHALL appear for entering the subtask title
- **AND** on submit, a new `TaskItem` is created with `parentTask` set to the current task
- **AND** the subtask inherits the parent's `reminderList` and default date
