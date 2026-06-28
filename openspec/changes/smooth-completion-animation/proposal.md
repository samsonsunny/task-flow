## Why

Completing a task currently jumps it to the end of the list before fading out — jarring and unlike any major task manager. The 0.6s grace period appends the task instead of keeping it in its natural sort position. Strikethrough is also missing from the completed visual state.

## What Changes

- `TimelineViewModel.update()` sorts `justCompleted` tasks naturally instead of appending them — no position jump
- `TaskRowView` adds `.strikethrough()` to completed task titles with 0.18s animation
- Existing `completion-animation` spec updated with position-stability requirement

## Capabilities

### New Capabilities
*(none)*

### Modified Capabilities
- `completion-animation`: Add requirement that completed task stays in its sorted position during the grace period; add explicit strikethrough to the completed visual state

## Impact

- `TaskFlow/Features/Tasks/Timeline/TimelineViewModel.swift`: ~2 lines in `update()`
- `TaskFlow/Views/Components/TaskRowView.swift`: 1 modifier added to title
- No model changes, no view structural changes
- List Detail path already keeps position stable — no change needed
