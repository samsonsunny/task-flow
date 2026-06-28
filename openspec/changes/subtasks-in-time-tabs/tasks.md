## Deferred — Pending Research

1. **Deep-dive research**: Document exactly how Apple Reminders and Todoist handle subtasks in Today/Scheduled/Upcoming views across all edge cases (parent due today + child due tomorrow, child undated, child in different list, etc.)
2. **Decision**: Choose inline nesting approach based on research findings
3. **Spec update**: Revise mental model spec to reflect new subtask behavior in time tabs
4. **Shared utility**: Design and implement `TaskTreeFlattener`
5. **ReminderSegmentViewModel**: Integrate tree flattening into time tab filtering pipeline
6. **View wiring**: Pass hierarchy params to `TaskRowView` in `ReminderSegmentDetailView`
7. **Refactor**: Replace inline flatten in `ListDetailViewModel` with shared utility
8. **Upcoming**: Handle section-grouped rendering with tree-flattened input
