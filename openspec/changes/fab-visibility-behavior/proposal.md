## Why

The Floating Add Button (FAB) is currently always visible as a fixed overlay. This creates three UX problems: (1) it remains visible during quick capture, where its primary action is already accomplished — the button becomes a dead control; (2) it overlaps swipe action buttons on the last list row, hiding the Delete action; (3) it stays visible during edit mode (reordering) where the user is in organization mode, not creation mode. The FAB should hide whenever the list has the user's manipulation attention.

## What Changes

- FAB hides during quick capture (redundant — user is already creating)
- FAB hides during swipe actions on list rows (prevents overlap)
- FAB hides during edit mode in DetailView (wrong interaction mode)
- FAB shows when none of the above conditions are active
- (Future consideration: scroll-based hide/show — deferred pending research)

## Capabilities

### New Capabilities
- `fab-visibility`: Controls when the FAB is shown and hidden based on list interaction state

### Modified Capabilities

None — this is a new behavior, not a change to existing requirements.

## Impact

- `TaskFlow/Features/FloatingAddButton.swift` — may need a visibility-binding or internal state
- `TaskFlow/Features/Tasks/Timeline/TimelineView.swift` — add FAB visibility logic tied to `activeCaptureDate`
- `TaskFlow/Features/Lists/DetailView.swift` — add FAB visibility logic tied to `isQuickCapturing` and `editMode`
- `TaskFlow/Features/Lists/ListView.swift` — no change (FAB opens an alert, no overlap issue)
- Swipe gesture detection on list rows may require custom gesture handling or `UIScrollViewDelegate` introspection
