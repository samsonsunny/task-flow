## Why

Users occasionally tap the complete button when they intended to tap the adjacent expand/collapse chevron (or vice versa). Both controls are 20×20pt touch targets sitting 12pt apart on the leading edge of the row. This is a fat-finger problem — the two actions have very different consequences (completing a task vs expanding subtasks) and a mis-tap creates frustration.

## What Changes

- Move the collapse/expand chevron from the leading edge (before the completion circle) to the trailing edge (after the title content), vertically centered
- Expand the tappable hit area of both the completion circle and the chevron from 20×20pt to 44×44pt (Apple HIG minimum) while keeping the visual size at 20×20pt
- The completion circle stays in its current leading position — no muscle memory change for the most common action

## Capabilities

### Modified Capabilities

- `task-row-display`: Chevron position changes from leading (before completion circle) to trailing (after title). Hit target size increases for both controls.

## Impact

- `TaskRowView.swift` — HStack reordering, `.contentShape` adjustment for expanded hit targets
- All call sites are unaffected (no API changes, same callbacks)
- No model changes, no migration, no breaking changes
