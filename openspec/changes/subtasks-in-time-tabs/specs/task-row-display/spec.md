## REMOVED Requirements

### Requirement: Segment views suppress nesting indicators
**Reason**: This requirement is superseded by the subtask-in-time-tabs change, which renders subtasks inline with full hierarchy (indentation, collapse/expand chevrons, subtask count) in all views. The suppression of nesting indicators in segment views was the old behavior; the new behavior applies nesting indicators universally.

**Migration**: Remove the suppression logic from `ReminderSegmentDetailView.taskListRow()` — tests and code that skip `nestingDepth`, `subtaskCount`, `isCollapsed`, and `onToggleCollapse` in segment views should be removed. The `TaskRowView` component already supports these parameters; they simply need to be wired through.
