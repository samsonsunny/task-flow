## Context

Context menus are implemented via SwiftUI's `.contextMenu` modifier on `TaskRowView`, the single reusable row component for reminders. Currently the context menu offers Today, Tomorrow, Later, and Schedule actions. Delete is only available through `.swipeActions(edge: .trailing)`, which is not discoverable on macOS and inconsistent with other iOS reminder apps.

## Goals / Non-Goals

**Goals:**
- Add a Delete button with destructive role to `TaskRowView.contextMenu`
- Provide an `onDelete` callback closure on `TaskRowView`
- Wire delete to `modelContext.delete(task)` in `ReminderSegmentDetailView` and `ListDetailView`

**Non-Goals:**
- Adding delete to `CompletedView` (uses inline rows, not `TaskRowView`)
- Adding confirmation dialog before delete (consistent with existing swipe-to-delete behavior)
- Any changes to swipe actions

## Decisions

- **Existing callback pattern**: Follow the existing optional closure pattern (`onMoveToToday`, `onSchedule`, etc.) — no new patterns needed
- **Destructive role**: Use `.role(.destructive)` for red styling, matching the swipe delete button
- **No confirmation**: Consistent with the existing swipe-delete which deletes immediately. A confirmation dialog would be a separate change

## Risks / Trade-offs

- **Accidental deletion**: Users can trigger delete from context menu without the intentionality of a swipe. Mitigation: the context menu requires two taps (long-press + tap), making accidental deletion unlikely; this matches the risk level of swipe delete
