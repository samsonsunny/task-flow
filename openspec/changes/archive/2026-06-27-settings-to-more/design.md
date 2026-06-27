## Context

The Settings view is presented as a `.sheet` from `MainTabView`, triggered by a `gearshape` toolbar button in each of the four tab views (Today, Tomorrow, Upcoming, Later). The view contains a notification toggle and a link to completed tasks. No structural changes to this arrangement — the icon and title are the only changes.

## Goals / Non-Goals

**Goals:**
- Replace `gearshape` with `ellipsis.circle` in all four tab toolbar buttons
- Rename navigation title from "Settings" to "More"
- Optionally rename `SettingsView.swift` → `MoreView.swift` (and corresponding `SettingsView` struct → `MoreView`) to keep code aligned with naming

**Non-Goals:**
- No behavioral changes to existing settings content
- No changes to the sheet presentation pattern
- No new features added to the More view (reserved for future changes)

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Icon | `ellipsis.circle` | Closest SF Symbol to Material's vertical three-dot; iOS conventions for overflow menus |
| File rename | Yes — rename `SettingsView.swift` → `MoreView.swift` | Keeps codebase consistent with UI naming; avoids confusion later |
| Struct rename | Yes — `SettingsView` → `MoreView` | Follows from file rename |
| Sheet pattern | Unchanged (`.sheet` from `MainTabView`) | No reason to change; works well |
| ViewModel | Not needed | View contains only `@AppStorage` and a `NotificationService` call — no business logic to extract |

## Risks / Trade-offs

- **File rename breaks imports** — `SettingsView` is referenced in `MainTabView.swift`. Low risk, quick fix.
- **Future ambiguity** — "More" could mean "more tasks" or "more app stuff." The `ellipsis.circle` icon cues the iOS "more actions" convention, which helps. If confusion arises, a future tab rename to "App" is straightforward.
