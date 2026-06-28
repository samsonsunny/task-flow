## 1. Rename SettingsView to MoreView

- [x] 1.1 Rename `SettingsView.swift` → `MoreView.swift` and struct `SettingsView` → `MoreView`
- [x] 1.2 Update `MainTabView.swift` — replace `SettingsView()` with `MoreView()`
- [x] 1.3 Rename navigation title from "Settings" to "More"

## 2. Swap toolbar icon in all tab views

- [x] 2.1 `TodayView.swift` — replace `gearshape` with `ellipsis.circle`
- [x] 2.2 `TomorrowView.swift` — replace `gearshape` with `ellipsis.circle`
- [x] 2.3 `UpcomingView.swift` — replace `gearshape` with `ellipsis.circle`
- [x] 2.4 `ListView.swift` — replace `gearshape` with `ellipsis.circle`

## 3. Verify

- [x] 3.1 Build and run — confirm no compile errors
- [x] 3.2 Confirm `ellipsis.circle` icon appears in all four tab toolbars
- [x] 3.3 Confirm sheet title reads "More" with all existing functionality intact
