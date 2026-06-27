## Context

`ReminderSegmentViewModel` persists tasks via `modelContext` and owns derived state (`filteredTasks`, `groupedSections`, `sortedFlatTasks`) computed in `update()`. The view calls `update()` on appear and when `@Query` results change via `.onChange`.

Currently, `toggleCompletion` mutates `task.isCompleted` directly but never calls `update()`, leaving all derived state stale. Even after the 0.6s `justCompleted` timer fires (meant to keep the row visible for the exit animation), `sortedFlatTasks` — a stored property set in the last `update()` call — still includes the completed task. The tab switch triggers a re-fetch + `update()` which finally corrects the state.

## Goals / Non-Goals

**Goals:**
- Completed tasks exit the timeline list after the 0.6s animation delay as specified
- Mutations in `toggleCompletion` immediately flush to SwiftData and recompute derived state
- The `justCompleted` mechanism continues to keep the row visible during the animation window

**Non-Goals:**
- No view-layer changes (exit animation is already wired via `.transition(.scale.combined(with: .opacity))` in `flatContent`)
- No spec changes (requirements are correct, implementation was incomplete)
- No changes to other mutation methods (delete, reschedule, move — they either call `modelContext.save()` or their effect is immediate and desired)

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Where to recompute state after mutation | Call `update(tasks:allTasks, lists:lists)` in `toggleCompletion` | Reuses the existing single-entry-point pattern. `allTasks` and `lists` are stored from the last `update()` and still reference the same objects (mutated in-place), so derived state reflects current model state. |
| How to trigger final removal after 0.6s | Call `update()` again in the `asyncAfter` after removing from `justCompleted` | The `justCompleted` set gates inclusion in `sortedFlatTasks`. After the timer removes the ID, `sortedFlatTasks` must be recomputed without it to let the row exit. |
| Save before update | `try? modelContext.save()` after mutation | Ensures SwiftData persists the change. Without save, `@Query` might not propagate, leaving view and VM out of sync on the next appearance. |

## Risks / Trade-offs

- [Calling `update()` twice] → Minimal cost (simple property reassignments, no I/O). The VM's `update()` is O(n) in task count but tasks are typically <100.
- [Race with view-initiated update] → The VM calls `update()` on the main actor synchronously, so a `.onChange`-triggered `update()` from the view can't interleave. The last `update()` wins.
