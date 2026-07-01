## Context

TaskFlow's `TaskItem` model already supports parent-child subtask relationships via `parentTask` / `subtasks`. The `ListDetailViewModel` recursively flattens subtrees into `FlatTaskNode[]` with depth, subtask count, and collapse/expand. `TaskRowView` accepts `nestingDepth`, `subtaskCount`, `isCollapsed`, and `onToggleCollapse` parameters and renders hierarchy (indentation, chevron, metadata).

**Current gap**: The time tabs pipeline (`ReminderSegmentViewModel` → `ReminderSegmentDetailView`) has no hierarchy awareness:
- `ReminderSegmentViewModel` filters tasks by `dueDate` and sorts them flat — no flattening, no collapse state
- `taskListRow()` in the view creates `TaskRowView` without any hierarchy parameters
- Subtasks only appear if they independently match the time filter; undated subtasks are invisible

## Goals / Non-Goals

**Goals:**
- Time tabs (Today, Tomorrow, Upcoming) render subtasks inline under their parent with indentation, collapse/expand chevrons, and subtask counts
- Two core rules:
  1. When a parent passes a time filter → ALL descendants appear inline (expandable/collapsible), regardless of their own due dates
  2. When a subtask independently passes a time filter but its parent does not → standalone at depth 0, no parent context pulled in
- Deduplication within the same view: if a subtask was already included via inline nesting, skip its standalone occurrence
- Shared `TaskTreeFlattener` utility extracted from `ListDetailViewModel` and used by both list and time tab VMs
- Collapse/expand state is per-view (each time tab + list detail maintain independent collapse sets)

**Non-Goals:**
- No changes to the data model (parentTask/subtasks already exists)
- No changes to drag-drop reparenting (already in list detail only)
- No changes to the editor view's subtask section
- No "parent surfaces based on child's date" behavior
- No auto-expand/collapse synchronization between views

## Decisions

### D1: Shared TaskTreeFlattener utility

Extract the flatten/collapse logic into a shared utility so both `ListDetailViewModel` and `ReminderSegmentViewModel` use identical logic.

```
struct FlatTaskNode: Identifiable {
    let id: PersistentIdentifier
    let task: TaskItem
    let depth: Int
    let subtaskCount: Int
}

struct TaskTreeFlattener {
    static func flatten(
        roots: [TaskItem],
        collapsed: Set<PersistentIdentifier>,
        includeCompleted: Bool = false
    ) -> [FlatTaskNode]
}
```

The flattener recursively walks subtrees. At each node:
1. Count non-completed direct subtasks (or all if `includeCompleted` is true)
2. If the node is collapsed, emit just the node and stop recursion
3. Otherwise emit the node, then recurse into children (sorted by `sortOrder`)

**Rationale**: The list detail already has working flatten logic (lines 100-117 of `ListDetailViewModel.swift`). Extracting it avoids duplication and ensures consistent behavior.

### D2: Time tab flattening pipeline

```
Current pipeline:
  @Query → ReminderSegmentVM.update()
    → filteredTasks = ReminderSegmentLogic.filteredTasks(tasks, for: segment)
    → sortedFlatTasks = sorted(filteredTasks)
    → groupedSections / upcomingGroups (sectioned by date)

New pipeline:
  @Query → ReminderSegmentVM.update()
    → matchedRoots = ReminderSegmentLogic.filteredTasks(tasks, for: segment)
    → build dedup set: union of all descendants of matchedRoots
    → standaloneTasks = tasks that match filter but are NOT descendants of any matchedRoot
    → flatNodes = TaskTreeFlattener.flatten(roots: matchedRoots, collapsed: collapsedTasks)
      + standaloneTasks as depth-0 nodes
    → sortedFlatTasks = sorted(flatNodes by their earliest date context)
    → upcomingGroups / groupedSections: build from flatNodes instead of raw tasks
```

**Rationale**: This cleanly separates the two rules. `matchedRoots` applies Rule 1 (include all descendants). `standaloneTasks` applies Rule 2 (orphan subtasks appear on their own). Dedup is handled by excluding any task already reachable from a root.

### D3: Collapse state per-view

Each `ReminderSegmentViewModel` instance (one per time tab) holds its own `collapsedTasks: Set<PersistentIdentifier>`. Separate from `ListDetailViewModel.collapsedTasks`.

**Rationale**: A user might want subtasks expanded in Today but collapsed in Upcoming. Different contexts have different density needs. Shared state would leak intent across screens.

### D4: Dedup via descendant check

When a subtask passes the time filter AND its parent also passes (or a higher ancestor passes), the subtask appears inline under the parent. It is NOT shown as a standalone row.

Implementation: After computing `matchedRoots` (roots that pass the filter), build a `Set<PersistentIdentifier>` of all reachable descendants. Any task that passes the filter but is NOT in that set becomes a standalone depth-0 node.

```
let rootIds = Set(matchedRoots.map(\.persistentModelID))
var allInlineIds = Set<PersistentIdentifier>()
for root in matchedRoots {
    collectDescendantIds(root, into: &allInlineIds)
}

let standalone = filteredTasks.filter { !rootIds.contains($0.persistentModelID) && !allInlineIds.contains($0.persistentModelID) }
```

**Rationale**: A task that's already visible under its parent doesn't need a duplicate row. This matches Todoist's approach and keeps the list clean.

### D5: Upcoming section grouping with tree-flattened data

The upcoming tab sections tasks by day/month. With tree flattening, a parent tree might span multiple days:
```
Parent due: MON
├── ChildA due: MON    → under parent in MON section ✓
├── ChildB due: TUE    → under parent in MON section (inherits parent's date context)
└── ChildC due: WED    → under parent in MON section
```

The entire flattened tree renders under the section that contains its root. Children are not independently sectioned.

**Rationale**: A tree is a conceptual unit. Splitting it across sections would destroy the hierarchy visual. The parent's date determines which section the tree belongs to. Children with different dates remain visible via collapse/expand (user can collapse to reduce noise).

### D6: Subtask count semantics

The count shows **total direct subtasks** (data model), not visible-in-context count.

**Rationale**: Consistent with list detail view. A user deciding whether to expand a parent needs to know how many children exist, not how many coincidentally share the same time slot.

## Risks / Trade-offs

- **Upcoming section complexity**: Current sectioning (`upcomingGroups`) assumes flat tasks. Tree-flattened input means entire subtrees live in one section even if children have different dates. The section rendering code must be adapted to handle `FlatTaskNode[]` instead of `TaskItem[]`.
  - *Mitigation*: Adapt the section builder to work with flat nodes directly. The group structure (day/month sections) stays the same — just the content inside each section switches from `[TaskItem]` to `[FlatTaskNode]`.

- **Performance with deep hierarchies**: Repeated `isDescendant` checks for dedup could be O(n²) on large flattened lists.
  - *Mitigation*: Pre-build the descendant ID set once (O(n) total), then check membership in O(1). Typical hierarchies are shallow (<5 levels) so this is unlikely to be an issue.

- **Collapse/expand animation in List**: SwiftUI `List` with row insertion/removal can be janky with `.animation()`.
  - *Mitigation*: Use `.animation(.easeInOut(duration: 0.2))` scoped to the right value, matching the existing pattern in `todayLikeContent`. Test on device.

- **Undated children newly visible**: Users who relied on subtasks being hidden in time tabs may be surprised when undated children appear.
  - *Mitigation*: This is the intended UX improvement. The collapse default is expanded, so users can collapse parents they don't want to see expanded.

- **Shared flattener changes existing behavior**: Extracting the flattener from `ListDetailViewModel` must not change its behavior.
  - *Mitigation*: Extract without changing logic. Verify `flatNodes` output matches before/after for the same inputs.
