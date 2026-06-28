## Why

The Settings view currently serves as a narrow configuration panel (daily reminder + completed tasks), but it's the natural overflow bucket for everything app-related that doesn't fit in the four task-focused tabs. Calling it "Settings" with a gear icon is semantically limiting — it boxes in what can go there. Renaming to "More" with a three-dot icon signals "everything else the app offers," future-proofing the view for upcoming additions (about, help, export, preferences, etc.) without needing a rename later.

## What Changes

- Replace `gearshape` SF Symbol with `ellipsis.circle` in the toolbar button on all four tab views
- Rename `SettingsView` navigation title from "Settings" to "More"
- No behavioral changes to existing content (notifications toggle, recently completed link)
- No change to the sheet presentation pattern — it remains a `.sheet` from `MainTabView`

## Capabilities

No new capabilities — this is a rebranding of an existing surface without behavioral changes. Future capabilities (about, help, export, etc.) will be proposed as separate changes.

### New Capabilities

None.

### Modified Capabilities

None — existing spec-level requirements are unchanged.

## Impact

- **`MainTabView.swift`**: No structural changes (sheet pattern stays)
- **`TodayView.swift`, `TomorrowView.swift`, `UpcomingView.swift`, `ListView.swift`**: Toolbar icon swap only
- **`SettingsView.swift`**: Navigation title rename, file may be renamed to `MoreView.swift` for consistency
