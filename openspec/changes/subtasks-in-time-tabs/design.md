## Context

TaskFlow supports nested subtasks via `TaskItem.parentTask` (inverse of `subtasks`). Currently:

- **List view** (`ListDetailView`): Uses `ListDetailViewModel.flattenTasks()` to recursively build `FlatTaskNode` array with `depth`/`subtaskCount`. Renders with indentation, collapse chevron, and inline children.
- **Time tabs** (`ReminderSegmentDetailView`): Uses `ReminderSegmentViewModel` which filters tasks by `dueDate` via `ReminderSegmentLogic.filteredTasks()`. Subtasks pass the filter independently if they have their own due date, and render as flat rows with no nesting info passed to `TaskRowView`.

## The Gap

`ReminderSegmentViewModel` has no hierarchy awareness. The `taskListRow()` function in `ReminderSegmentDetailView` creates `TaskRowView` without:
- `nestingDepth`
- `subtaskCount`
- `isCollapsed`
- `onToggleCollapse`

A subtask without its own `dueDate` never appears in time tabs at all (the filter excludes it).

## Explored Approaches

### Option A: Apple's Model (as documented)
Parent in smart lists shows a blue "2 subtasks" link. Subtasks with their own due date appear as flat standalone rows. Subtasks without due dates are invisible (drill into parent to see them). **No inline nesting.**

This is what the original design implemented (minus the blue link). Users find this frustrating — per Apple Community threads and blog posts.

### Option B: Todoist-style inline nesting
Parent tasks in Today/Upcoming are expandable with children nested beneath them. Children with their own due dates appear inline under parent (deduplicated — not also standalone). Children without due dates appear inline under parent.

This is more ambitious than Apple and matches the existing `ListDetailView` UX.

### Option C: Mixed
Subtasks without their own due date → nest under parent (inheriting parent's date context). Subtasks with their own due date → appear in their own time-slot section, but with indentation and hierarchy context preserved.

## Open Questions (Deferred)

1. **Upcoming deduplication**: When a subtask's due date differs from its parent, which date section does it render in? The parent's (destroying the subtask's independent date) or its own (breaking hierarchy continuity)?

2. **Collapse state scope**: Should collapse state be shared between list view and time tabs? Likely no — different contexts.

3. **Subtask count accuracy**: If a parent appears in Today with 3 subtasks but only 1 is visible (the other 2 have different dates), should the count show 3 (data model) or 1 (visible)?

4. **Apple vs Todoist deeper research**: Exact behavior of both apps in edge cases — subtask with date T+1 under parent due today, shown in Tomorrow tab? Shown in both?

5. **Animations**: Collapse/expand transitions in `List` context (can be janky if not done carefully).

## Proposed Solution Sketch (Tentative)

```
Shared: TaskTreeFlattener
├── struct TaskTreeNode { task, depth, subtaskCount }
├── func flatten(roots, collapsed, shouldInclude: (TaskItem) -> Bool) -> [TaskTreeNode]
└── handles deduplication: if a subtask was included via a parent, skip its standalone occurrence

Used by:
├── ListDetailViewModel (replace inline flattenTask/flattenNode)
└── ReminderSegmentViewModel (new: build tree from filtered roots + include all children)
```

For time tabs specifically:
1. Run `ReminderSegmentLogic.filteredTasks()` to get root tasks that match
2. For each matched root, recursively include ALL descendants (regardless of their own dates)
3. Deduplicate: skip any subtask that was included via a parent from appearing standalone
4. For subtasks that matched the filter but whose parent didn't: render standalone at depth 0

## Files Affected

| File | Change |
|---|---|
| New: `TaskTreeFlattener.swift` (shared utility) | `TaskTreeNode` + `flatten()` |
| `ListDetailViewModel.swift` | Replace inline `flattenTasks`/`flattenNode` with shared utility |
| `ReminderSegmentViewModel.swift` | Add tree flattening, `flatNodes`, `collapsedTasks` |
| `ReminderSegmentDetailView.swift` | Pass `nestingDepth`/`subtaskCount`/`onToggleCollapse` to `TaskRowView` |
| `openspec/specs/app-mental-model/spec.md` | Update mental model — subtasks included under parent in time tabs |

## Risks

- **Behavior mismatch with Apple**: If the goal is to match Apple, this over-delivers (more nesting than Apple provides). If the goal is better UX, this is fine — but the decision needs to be conscious.
- **Upcoming section grouping complexity**: The current section/group code assumes flat tasks. Tree-flattening before sectioning adds complexity.
- **Performance on large hierarchies**: Fine for typical use but needs consideration for 100+ item lists.
