## MODIFIED Requirements

### Requirement: Subtask behavior in time tabs
The subtask display in time tabs SHALL follow these rules:

**Rule 1**: When a task passes a time filter via its own `dueDate`, all its descendants appear inline beneath it regardless of their own `dueDate` values. This includes subtasks with no due date (which gain visibility from their ancestor's date context).

**Rule 2**: A subtask that independently passes a time filter but whose parent does not appears standalone at depth 0. No parent context is pulled in.

**Collapse/expand**: Each parent in a time tab is expandable/collapsible independently. Collapse state is per-view (not shared with the list detail or other time tabs).

**Dedup**: Within a single view, a task rendered inline via Rule 1 is not also shown as a standalone row.
