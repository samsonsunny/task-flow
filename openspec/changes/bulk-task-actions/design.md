## Context

TaskFlow is a SwiftUI/SwiftData task management app following MVVM architecture. All task list screens (Today, Tomorrow, Upcoming, Later/ListDetailView, Completed) display tasks via `TaskRowView` with completion circles, context menus, and swipe actions. There is currently no multi-select or bulk action infrastructure.

The existing ellipsis (⋯) button on Today/Tomorrow/Upcoming/Later navigates directly to Settings. ListDetailView and CompletedView have no toolbar at all.

Key existing patterns:
- ViewModels are `@Observable` classes receiving `modelContext` at init
- Views hold `@Query` for data, ViewModels receive data via `update()`
- All task mutations route through ViewModel methods (`toggleCompletion`, `delete`, `moveTask`, `rescheduleTo*`, etc.)
- `TaskRowView` accepts callback closures for each action

## Goals / Non-Goals

**Goals:**
- Apple-style selection mode: ⋯ → "Select Items" → selection circles + bottom toolbar + "Done"
- 5 bulk actions: Date, Move, Tag/Priority, Complete, Delete
- Selection state as `@State` in View, ViewModel receives selected set as parameter
- Independent selection per row (including subtasks)
- Auto-expand subtasks on enter, restore collapse state on exit
- Consistent across all 6 task list screens

**Non-Goals:**
- Drag-to-reorder in selection mode (disabled during selection)
- Undo/redo for bulk operations
- Bulk edit of task title/description/notes
- Selection persistence across screen navigation
- Two-finger swipe gesture entry (can add later)

## Decisions

### D1: Selection state lives in View as `@State`

**Decision**: `@State var isSelecting: Bool` and `@State var selectedTasks: Set<PersistentIdentifier>` in each View that supports selection.

**Rationale**: Selection is UI state — which checkboxes are checked. Per AGENTS.md, UI-only state stays in the View. ViewModels receive the selected set as a parameter to bulk methods, keeping them pure.

**Alternatives considered**:
- ViewModel-owned selection: Violates "UI-only state in View" principle. ViewModels would need to track selection which is presentation concern.
- Shared selection manager: Over-engineered for this scope. Each screen is independent.

### D2: ⋯ becomes a Menu, replaces with "Done" during selection

**Decision**: The existing ⋯ `Button` becomes a `Menu` with "Select Items" as first item, followed by "Settings". During selection mode, "Done" replaces the ⋯ entirely.

**Rationale**: Matches Apple Reminders exactly. "Select Items" is the first menu item for discoverability. "Done" as a plain button (not menu) is clear exit signal.

**Alternatives considered**:
- Dedicated "Select" toolbar button: Adds chrome. ⋯ menu is cleaner and Apple-standard.
- Long-press gesture: Low discoverability, conflicts with existing context menu.

### D3: Selection circle replaces completion circle

**Decision**: In selection mode, the completion circle is hidden and replaced by a selection circle in the same position. Tapping the circle or the row toggles selection.

**Rationale**: Avoids two circles per row (visual noise). Matches Apple pattern where selection circle IS the primary circle in selection mode. Completion is disabled during selection — consistent with Apple Reminders.

**Alternatives considered**:
- Two circles (selection + completion): Too noisy.
- Row highlight only (no circle): Less tactile, harder to see selected state.
- Selection circle on far left, completion stays: Better but still cluttered.

### D4: Row tinting for selection feedback

**Decision**: Selected rows get a subtle blue background tint. Unselected rows in selection mode get no tint (or very subtle).

**Rationale**: The tint provides immediate visual confirmation of "you're in selection mode" even before selecting anything (all rows get a very subtle tint), and clearly shows which items are selected.

### D5: Bottom toolbar as a separate component

**Decision**: Create a `BulkActionsToolbar` view that takes binding for selection state and callback closures for each action. Appears as an overlay at the bottom of the screen during selection mode.

**Rationale**: Shared across all 6 screens. Keeps the toolbar logic out of individual Views. Clean separation.

### D6: Subtasks auto-expand on enter, restore on exit

**Decision**: When entering selection mode, save current `collapsedTasks` set, then clear it (expand all). On exit, restore the saved set.

**Rationale**: Users can't select subtasks they can't see. Expanding all gives full visibility. Restoring on exit preserves the user's preferred view state.

### D7: Bulk operations loop over existing ViewModel methods

**Decision**: Each bulk operation calls the existing single-task ViewModel method in a loop over `selectedTasks`. No new SwiftData operations needed.

**Rationale**: Existing methods handle all edge cases (notifications, haptics, modelContext.save). Looping is simple and correct. `update()` called once after all mutations.

**Alternatives considered**:
- Batch SwiftData operations: More complex, not needed for typical selection sizes (<50 tasks).

## Risks / Trade-offs

- **Performance with large selections**: Looping through many tasks could cause UI lag if `update()` is called per-task. → Mitigation: Call `update()` once after all mutations complete.
- **Context menu disabled in selection mode**: Users might expect context menu to still work. → Mitigation: Clear visual signal (selection circles + tint + toolbar) makes the mode change obvious.
- **CompletedView has different row structure**: Uses inline uncomplete button, not `TaskRowView`. Selection circle needs to be added differently. → Mitigation: Create selection circle as a modifier or overlay that works with any row structure.
- **DetailView has drag-drop**: Drag-drop should be disabled during selection mode to avoid conflicts. → Mitigation: Conditionally disable `.onDrag`/`.onDrop` when `isSelecting`.
