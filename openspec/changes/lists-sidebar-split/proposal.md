## Why

The single segmented control puts **"Inbox"** (a *place*) on the same visual level as **Today / Tomorrow / Upcoming** (time *horizons*). Mixing the two axes flattens the app's mental model (when vs. where), so the user never feels like any segment is where tasks are *supposed* to go — and takes no action. The capture bar compounds this: it floats below the lists overview too, where there is no single task surface to add to, so the bar reads as disconnected from the list the user is actually looking at.

## What Changes

- **BREAKING**: Replace the single-page 4-segment layout with a `NavigationSplitView` root.
  - **Sidebar column** = the Lists surface (default Inbox, groups, lists) — the "where" of the mental model, restored to its own column.
  - **Detail column** = the time home — a segmented control with only **Today / Tomorrow / Upcoming** — the "when".
- `HomeSegment` loses its `.organize` case; the segmented picker shows the three time segments only.
- **Capture bar visibility becomes context-dependent** (supersedes the "always-on bar" rule):
  - **Visible** on the time segment roots (Today, Tomorrow, Upcoming) — target = the segment's date.
  - **Visible** in `ListDetailView` — target = that list, undated.
  - **Hidden** on the Lists overview (sidebar / list-of-lists) — no task surface to capture into there.
- `ListsTabView` content moves into the sidebar column, stripped of the header accessory and capture-bar bottom inset.

## Capabilities

### New Capabilities

- `split-view-navigation`: `NavigationSplitView` root with Lists in the sidebar column and the three-segment time home (Today/Tomorrow/Upcoming) in the detail column. Defines the two-axis navigation surface, segment switching, and column behavior.

### Modified Capabilities

- `app-mental-model`: Requirements describing navigation change from a single 4-tab `TabView` / flat segmented home to the sidebar-split two-column model.
- `tab-bar-navigation`: Replaced — root-navigation requirements move to the split-view model; the 4-tab `TabView` requirement is superseded.
- `quick-capture`: Capture-bar presence rules change from "always visible on every surface" to surface-aware — visible on time segment roots and inside list detail, hidden on the Lists overview.

## Impact

- `TaskFlow/Features/MainTabView.swift` — rewrite: `NavigationSplitView` root; sidebar = Lists, detail = 3-segment time home + capture bar.
- `TaskFlow/Features/Lists/ListView.swift` — `ListsTabView` becomes sidebar content: remove `headerAccessory`, capture-bar bottom margin; keep group/list rows, creation, reorder.
- `TaskFlow/Views/Components/CaptureBar.swift` / `CaptureBarViewModel.swift` — target resolution and presence move per-surface; `resolveTargetDate` drops the `.organize` branch.
- `TaskFlow/App/AppState.swift` — `activeListID` reused as the list-detail capture target.
- `TaskFlow/Features/Tasks/{TodayView,TomorrowView,UpcomingView}.swift` — unchanged wrappers; headers simplified to the 3-segment picker.
- UI tests referencing the old `Later` tab and FAB are already stale and updated as part of this change.