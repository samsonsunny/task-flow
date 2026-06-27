## Why

The attention-tab headers (Today, Tomorrow, Upcoming) each display the current date as a visual anchor, but they use inconsistent font weights — Today/Tomorrow use `.subheadline` while Upcoming uses `.headline` for dates with tasks. This undermines the visual hierarchy and feels unpolished.

## What Changes

- Today tab's date subtitle changes from `.subheadline` to `.headline`, matching Upcoming's active date style
- Tomorrow tab's date subtitle changes from `.subheadline` to `.headline`, matching Upcoming's active date style
- No format change — all three tabs already display the same date format ("EEE, d MMM" or locale-equivalent)

## Capabilities

### New Capabilities

None — this is a visual consistency fix, not a new feature.

### Modified Capabilities

None — no spec-level behavior changes. The date string, position, and color remain the same; only the font weight changes.

## Impact

- **TimelineView.swift** (~10 lines): Update the Today/Tomorrow date subtitle font modifier
- No API, data model, or architectural changes
