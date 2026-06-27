## Context

Today/Tomorrow tabs render the date as a list row using `.subheadline` font (TimelineView.swift:73-82). Upcoming renders its active dates as section headers using `.headline` font (`dayHeader` at line 320-335). Users perceive this as an inconsistency in visual hierarchy — the date should carry the same weight regardless of which tab is active.

The date format is already consistent across all three tabs (locale-appropriate, includes day-of-week).

## Goals / Non-Goals

**Goals:**
- Today and Tomorrow date subtitles use `.headline` font weight
- Visual hierarchy consistent across Today, Tomorrow, and Upcoming

**Non-Goals:**
- No changes to date format, color, positioning, or structure
- No changes to Upcoming's date rendering
- No architectural changes

## Decisions

| Decision | Chosen approach | Alternative | Rationale |
|---|---|---|---|
| Font weight | `.headline` | `.subheadline` (current) | Matches Upcoming's active date style; user confirmed preference |
| Implementation scope | Single modifier change in `TimelineView.swift` | Extract shared date component | Overkill for a 1-line change |

## Risks / Trade-offs

- **Structural difference remains**: Today/Tomorrow date is a list row, Upcoming's is a section header. They'll look the same but won't behave identically (sticky headers, padding). The user has acknowledged this and considers visual consistency sufficient.
