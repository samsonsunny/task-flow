## ADDED Requirements

### Requirement: ViewModel owns flat node computation
The ViewModel SHALL compute `flatNodes` from the task list, flattening the nested subtask hierarchy according to collapse state. Each flat node SHALL contain the task, its depth, and its visible subtask count.

#### Scenario: Flat nodes computed from root tasks
- **WHEN** the ViewModel receives an updated task list
- **THEN** `flatNodes` SHALL contain one entry per visible task (root tasks and non-collapsed subtasks) with correct depth values

#### Scenario: Collapsed subtasks excluded from flat nodes
- **WHEN** a parent task's persistentModelID is in `collapsedTasks`
- **THEN** its subtasks SHALL NOT appear in `flatNodes`

### Requirement: ViewModel owns completion lifecycle
The ViewModel SHALL handle task completion toggling including haptic feedback, `justCompleted` animation tracking with auto-removal after 600ms, and notification cancellation upon completion.

#### Scenario: Toggle completion marks task
- **WHEN** `toggleCompletion(for:)` is called on an incomplete task
- **THEN** `task.isCompleted` SHALL be set to `true`, `task.completionDate` SHALL be set to now, and any pending notification SHALL be cancelled

#### Scenario: Recent completion tracked for animation
- **WHEN** a task is completed
- **THEN** its taskId SHALL be added to `justCompleted` and automatically removed after 600ms

### Requirement: ViewModel owns drag-drop reorder
The ViewModel SHALL handle drag-drop reorder within the list and between parent/child relationships, using the existing `midpoint`/`widen` algorithm for sort order assignment.

#### Scenario: Drop reorders siblings
- **WHEN** a task is dropped at a new position among its siblings
- **THEN** the sort orders SHALL be reassigned using the midpoint algorithm preserving order of non-moved items

#### Scenario: Drop creates parent-child relationship
- **WHEN** a task is dropped onto another task's lower region
- **THEN** the dragged task SHALL become a child of the target task

### Requirement: ViewModel owns quick capture
The ViewModel SHALL handle quick capture task creation, inserting the task into the current list with appropriate sort order.

#### Scenario: Quick capture creates task
- **WHEN** `commitQuickCapture(text:in:)` is called with non-empty text
- **THEN** a new `TaskItem` SHALL be inserted into the model context with the given text and list, with a sort order placing it at the end

### Requirement: ViewModel owns deletion
The ViewModel SHALL handle task deletion including notification cancellation.

#### Scenario: Delete cancels notification and removes task
- **WHEN** `delete(task:)` is called
- **THEN** any pending notification for the task SHALL be cancelled and the task SHALL be deleted from the model context
