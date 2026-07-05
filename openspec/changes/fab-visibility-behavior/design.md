## Context

The FAB is used in three views: `ReminderSegmentDetailView` (Today/Tomorrow/Upcoming), `ListsTabView` (Later tab), and `ListDetailView` (list detail). In all three it's a fixed `.overlay(alignment: .bottomTrailing)` with no visibility logic.

Current problem states:
- **Quick capture active** (`activeCaptureDate != nil` or `isQuickCapturing == true`): FAB remains visible but its action is already consumed — the user is typing a task. Tapping again is a no-op.
- **Swipe action on last row**: The FAB sits in the z-layer above the list, overlapping the Delete button on the trailing edge of the bottommost row.
- **Edit mode (`editMode.isEditing == true`)**: FAB is visible in DetailView during reorder, but the user is organizing, not creating.

The `LatestTabView` FAB opens an alert — not affected by any of these problems.

## Goals / Non-Goals

**Goals:**
- Hide FAB when quick capture is active in `ReminderSegmentDetailView` and `ListDetailView`
- Hide FAB when a swipe action is revealed on any row
- Hide FAB when `editMode.isEditing == true` in `ListDetailView`
- Show FAB when none of the above conditions are true
- Clean separation: visibility logic stays in the view (UI-only concern, not ViewModel)

**Non-Goals:**
- Scroll-based hide/show (deferred — needs `UIScrollView` offset tracking research)
- Animation work beyond standard SwiftUI `transition(.opacity)` or `.animation()`
- Changes to `ListsTabView` behavior (its FAB opens an alert — no conflict)

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Visibility mechanism | Conditional overlay (`if !hidden { FAB }`) | Simpler than binding on FAB; avoids threading state backwards into the button component |
| Swipe detection | `UIScrollViewDelegate` via `Introspect` or `UIViewRepresentable` | No native SwiftUI callback for "swipe action revealed"; need to detect `scrollViewWillBeginDragging` / `scrollViewDidEndDragging` and intersection checks |
| Quick capture tracking | Already have `activeCaptureDate` / `isQuickCapturing` state in the view | No new state needed — just check existing bool |
| Edit mode tracking | Already have `@Environment(\.editMode)` in `ListDetailView` | No new state needed |
| State consolidation | Combine all signals into a single computed `isFABHidden` | One source of truth, easy to extend |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Swipe detection via `UIScrollViewDelegate` may be fragile across iOS versions | Fall back to always-visible FAB if detection fails (graceful degradation) |
| Quick capture transition (FAB hides, row appears) could feel janky if badly timed | Keep `withAnimation(.easeInOut(duration: 0.2))` consistent with existing animations |
| Adding `UIViewRepresentable` for scroll tracking adds complexity | Defer swipe detection to a follow-up if implementation cost is high; start with quick capture + edit mode only |
