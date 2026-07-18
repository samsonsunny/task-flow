## Context

`TaskRowView` is the single task row component used across all list screens. Currently, the collapse/expand chevron sits at the leading edge, immediately before the completion circle, with 12pt spacing between them. Both are 20×20pt touch targets. Users with larger fingers occasionally tap the wrong control — completing a task when they meant to expand subtasks, or vice versa.

Current layout:
```
[chevron 20×20] 12pt [circle 20×20] 12pt [title...]
```

## Goals / Non-Goals

**Goals:**
- Eliminate the fat-finger mis-tap between complete and expand controls
- Expand touch targets to Apple HIG minimum (44×44pt) while keeping visual size at 20×20pt
- Follow iOS convention: trailing chevrons for disclosure/navigation

**Non-Goals:**
- Changing the completion circle visual design
- Changing the row's vertical padding or spacing
- Modifying any ViewModel logic or callbacks
- Changing context menu behavior

## Decisions

### Decision 1: Move chevron to trailing edge

Reorder the `HStack` from `[chevron, circle, title]` to `[circle, title, chevron]`.

**Rationale:** Maximizes physical distance between the two interactive controls. Follows iOS convention where trailing chevrons indicate "tap to go deeper." The completion circle keeps its current position — no muscle memory change for the most common action.

**Alternatives considered:**
- Increasing only the gap (e.g., 24pt spacing) — doesn't solve the root problem, both still on same side
- Moving complete to trailing instead — less conventional, completion is a higher-frequency action that benefits from leading position

### Decision 2: Expand hit targets with contentShape

Keep the visual elements at 20×20pt but expand the tappable area using `.contentShape(Rectangle().size(width: 44, height: 44))` on each button, or by wrapping each in a larger transparent tap target.

**Rationale:** Apple HIG recommends 44×44pt minimum. The visual design stays clean while usability improves significantly.

**Alternative considered:** Making the visual elements larger (44×44pt circles) — would change the entire row's visual proportion and feel oversized on the leading edge.

### Decision 3: Vertically center both controls

The `HStack` already uses `alignment: .center`. Both controls are 20×20pt frames. No change needed — they will naturally center vertically regardless of title line count.

**Rationale:** Industry standard for row-level affordances. Both are row-level actions, not line-level actions.

## Risks / Trade-offs

- **[Risk] Swipe-to-delete conflict on trailing edge** → Currently no swipe actions exist on `TaskRowView` (only context menu via long-press). No conflict. If swipe actions are added later, the chevron would need a dedicated tap target that doesn't interfere.
- **[Risk] Trailing chevron feels crowded with listRowInsets** → The standard trailing inset is 16pt, which provides natural breathing room. The 20×20pt chevron visual fits comfortably.
- **[Trade-off] Title gets less horizontal space** → The title now shares width with a trailing chevron (20×20pt + 12pt spacing = 32pt less). This is minimal and titles already wrap naturally.
