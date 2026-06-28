## ADDED Requirements

### Requirement: ViewModel owns draft state and initialization
The ViewModel SHALL initialize a `ReminderDraft` from either an existing `TaskItem` (for editing) or from default values with optional `initialDate`, `initialListID`, and `initialTitle` (for creation). The ViewModel SHALL hold both the current `draft` and the `initialDraft` for dirty comparison.

#### Scenario: Initialize from task for editing
- **WHEN** the ViewModel is initialized with a `TaskItem`
- **THEN** `draft` SHALL be initialized from the task via `ReminderDraft(task:)` and `initialDraft` SHALL be an identical copy

#### Scenario: Initialize from defaults for creation
- **WHEN** the ViewModel is initialized without a task
- **THEN** `draft` SHALL start as `ReminderDraft.empty` with `initialDate`, `initialTitle` applied, and `initialDraft` SHALL be an identical copy

### Requirement: ViewModel validates before save
The ViewModel SHALL validate that the draft has meaningful content before saving, returning nil if invalid.

#### Scenario: Save returns nil for empty draft
- **WHEN** `save()` is called with an empty draft
- **THEN** no model mutation SHALL occur and the method SHALL return nil

### Requirement: ViewModel owns save pipeline
The ViewModel SHALL handle the full save pipeline: applying draft to a `TaskItem` via `ReminderDraftMapper.apply()`, inserting new tasks into the model context, assigning initial sort order, and scheduling notifications when the draft includes a time.

#### Scenario: Save creates new task
- **WHEN** `save()` is called with valid content and no existing task
- **THEN** a new `TaskItem` SHALL be inserted into the model context with the draft's content applied, `createdAt` and `taskId` assigned, and notification scheduled if hasTime is true

#### Scenario: Save updates existing task
- **WHEN** `save()` is called on an existing task
- **THEN** the existing task SHALL be updated via `ReminderDraftMapper.apply()` and notifications SHALL be rescheduled if hasTime changed

### Requirement: ViewModel tracks dirty state
The ViewModel SHALL expose `isDirty` as true when the current `draft` differs from `initialDraft`.

#### Scenario: Draft modified is dirty
- **WHEN** a draft property is changed
- **THEN** `isDirty` SHALL be true if the draft differs from initialDraft

### Requirement: ViewModel owns subtask operations
The ViewModel SHALL handle subtask creation, deletion, and completion toggling.

#### Scenario: Add subtask inserts child task
- **WHEN** `addSubtask(title:to:)` is called with non-empty title
- **THEN** a new `TaskItem` SHALL be inserted as a child of the parent with sort order at the end
