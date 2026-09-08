## Context

The root navigation is a single-page layout: one shared `NavigationStack` hosting a 4-segment segmented control (Inbox, Today, Tomorrow, Upcoming) with a persistent capture bar pinned via a bottom `safeAreaInset` (`MainTabView.swift`). The Lists surface (`ListsTabView`) renders inside the shared stack with the segment picker injected as a header row, and the capture bar sits below it permanently.

Two problems stem from this:
1. **Flat hierarchy** — Inbox (`HomeSegment.organize`) shares a control with Today/Tomorrow/Upcoming. A *place* (Lists) is displayed at the same visual weight as three *time horizons*, so no segment reads as "where tasks go", and users don't take action.
2. **Disconnected capture** — on the Lists overview, the capture bar floats under a grid of list rows with no single task surface to add to, so the bar looks unrelated to what's on screen.

The app is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`).

## Goals / Non-Goals

**Goals:**
- Restore the two-axis model (`app-mental-model`): Lists on the "where" axis, time segments on the "when" axis, as a `NavigationSplitView`.
- Lists surface lives in the sidebar column; the segmented time control (Today/Tomorrow/Upcoming) lives in the detail column.
- Capture bar appears only on task surfaces — time segment roots and a selected list's tasks — and never on the Lists overview.
- Keep the existing MVVM structure, `@Query` in views, `@Observable` ViewModels, and the segment/timeline logic unchanged.

**Non-Goals:**
- Reintroducing the old `AppNav` enum, smart-filter sidebar sections, or the large detail `switch` from the pre-tab-bar era.
- New task-capture patterns (the editor sheets, per-day Upcoming capture, target-chip semantics stay as-is).
- iPad-specific layout adaptation.
- Content/pipeline work for the App Store "Later"→name changes flagged in `single-page-home`.

## Decisions

### Decision 1: NavigationSplitView root

**Chosen:** `MainTabView` becomes a `NavigationSplitView`. Sidebar column = Lists; detail column = time home (three-segment control + segment content + capture bar).

```swift
NavigationSplitView {
    ListsSidebarView(selection: $selectedListID)      // the "where"
} detail: {
    detailColumn                                       // the "when" (or selected list)
}
```

**Alternatives considered:**
- Bottom `TabView` (restore old 4-tab): user explicitly rejected; keeps both axes at equal visual weight — the confusion returns.
- Toolbar-button push to Lists: hides the "where" axis behind a link instead of giving it a persistent column.
- Flat 3-segment control only (no Lists): removes Inbox from the control but leaves Lists unreachable.

### Decision 2: Detail column switches between time home and a selected list

**Chosen:** The detail column is driven by a single selection state `@State var selectedListID: ReminderList.ID?` from the sidebar. `nil` → time home; `some(id)` → `ListDetailView(listID:)`.

```swift
@ViewBuilder private var detailColumn: some View {
    if let id = selectedListID {
        CaptureHost(target: .list(id)) { ListDetailView(listID: id) }
    } else {
        CaptureHost(target: .segment(selectedSegment)) {
            TimeHomeView(segment: $selectedSegment)
        }
    }
}
```

This is intentionally *not* the old `AppNav` + `switch` (which also switched the detail column). Here the sidebar holds only lists, not smart filters, and the time home keeps its own segmented control inside the detail column.

**Alternatives considered:**
- Pushing `ListDetailView` via `NavigationLink` from sidebar rows: works, but the detail column then needs its own back-stack; selection-based content is the natural split-view pattern and keeps "back" simple.
- Keeping `appState.activeListID` as the sole driver: reachable, but a local `selectedListID` makes the sidebar↔detail binding explicit and testable.

### Decision 3: Capture bar presence is surface-aware — owned by the detail column

**Chosen:** Move capture-bar ownership out of the root `safeAreaInset` into a shared `CaptureHost` wrapper used by both detail surfaces. The bar is attached to the *detail column's* `NavigationStack` bottom inset, so:
- time segment roots → bar visible, target = segment;
- selected list tasks → bar visible, target = that list;
- Lists overview (sidebar) → the host isn't mounted, so no bar appears.

```swift
struct CaptureHost<Content: View>: View {
    let target: CaptureTarget        // .segment(HomeSegment) | .list(ReminderList.ID)
    @ViewBuilder let content: Content
    // creates/owns CaptureBarViewModel; attaches CaptureBar via safeAreaInset
}
```

The existing `CaptureBarViewModel`, `CaptureBar`, and `AppState.pendingCaptureDate` (Upcoming day-header fast path) stay as-is. The one `CaptureBarViewModel` instance and the minute-aligned timer move from `MainTabView` into the host (or stay on `MainTabView` and are passed down — whichever keeps a single instance; both surfaces never render simultaneously, so a per-host instance is fine).

**Alternatives considered:**
- Conditionally hiding the bar in `ListsTabView` via `.hidden()`: leaves dead layout space and the shared-timer coupling in the root; host-based composition removes the bar entirely from the overview.
- Keeping the bar at the split-view root: on compact (iPhone) the root inset would also appear over the sidebar column — exactly the misleading case we're removing.

### Decision 4: CaptureTarget replaces HomeSegment-only resolution

**Chosen:** `CaptureBarViewModel.resolveTargetDate/resolveTargetList` are superseded by an explicit `CaptureTarget` steering `commit`:

- `.segment(s)` → `dueDate` from `resolveTargetDate(s, overrideDate:)`; list = default Inbox.
- `.list(id)` → `dueDate = nil`; list = resolved `id`.

`HomeSegment.organize` is removed, so `CaptureBarViewModel` no longer has an Inbox segment branch.

**Alternatives considered:**
- Keep `HomeSegment` and overload with `activeListID`: works but leaves a dead `.organize` case and muddies "no date" vs "segment date" semantics.

### Decision 5: ListsTabView becomes sidebar content

**Chosen:** `ListsTabView` is renamed/slimmed to a sidebar view: remove the `headerAccessory` injection and the capture-bar bottom `contentMargins`; keep group/list rows, `DisclosureGroup`s, reorder, create-list/group sheets, rename/delete context menus, and the Inbox-pinned-first ordering. Add `List(selection:)` binding and the toolbar create button already present on this surface.

**Alternatives considered:**
- Leaving `ListsTabView` in the detail column and only hiding the bar: the flat-hierarchy problem (Inbox at the same level as Today) would remain.

### Decision 6: Launch lands on the time home

**Chosen:** `selectedListID` starts `nil`, so the detail column opens on Today (respecting `UITEST_OPEN_UPCOMING`). The sidebar is reachable through the standard split-view reveal control on compact width; the UI tests assert the detail column shows the time home at launch.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| [Back-to-basics] Returning to `NavigationSplitView` resurrects a pattern removed in June 2026 for iPhone complexity | The sidebar is now lists-only (no smart filters) and drives a single explicit `selectedListID` state; time switching stays in the detail column's segmented control, giving the two-axis separation that motivated the removal. |
| [Compact-width reveal] On iPhone the sidebar may default to hidden; users could miss the Lists surface | `UITEST`/preview fixtures assert launch shows the time home; the split-view reveal button is the standard iOS affordance and the toolbar "+" create entry remains available in the sidebar. |
| [Capture target ambiguity] Same bar, two targets (segment-vs-list) | `CaptureTarget` is explicit per host; the bar's target chip logic is unchanged and already always-on. |
| [Double Inbox label] A list named "Inbox" plus no segment anymore | Removing `.organize` eliminates the second "Inbox"; the sidebar still shows the single default Inbox list row (named "Inbox"), consistent with `ReminderDefaults`. |
| [Stale UI tests] Tests still drive the removed `Later` tab / FAB IDs | Tasks include updating `TaskFlowUITests` / `TaskFlowSubtasksUITests` to the split-view + capture-bar model. |

## Migration Plan

1. `HomeSegment`: remove `.organize` case.
2. `MainTabView`: convert to `NavigationSplitView`; add `selectedListID`; extract `TimeHomeView` (detail: segment picker + segment content); move capture-bar mounting into `CaptureHost`.
3. `CaptureBarViewModel`: add `CaptureTarget` and route `commit` through it; delete the `.organize` branch.
4. `ListView.swift`: slim `ListsTabView` → sidebar content (drop `headerAccessory`, capture margins; add selection binding).
5. `DetailView.swift`: keep `ListDetailView`; confirm `appState.activeListID` no longer needs onAppear/onDisappear for capture (host passes the list directly); adjust if other consumers exist.
6. Update stale UI tests to the segmented/split model (drop `Later` tab taps and `reminder-create-button` FAB queries).

Rollback: `MainTabView` returns to the single `NavigationStack` + segmented control; `HomeSegment.organize` is re-added; the root `safeAreaInset` CaptureBar returns. All model/segment logic is untouched, so reversion is low-risk.

## Open Questions

- Whether `appState.activeListID` is still read anywhere besides `ListDetailView` (e.g., editor defaults). If unused elsewhere, it can be dropped from `AppState` in this change; otherwise keep it set from `selectedListID`.
- Whether the sidebar should also expose a "Completed" entry point (currently reachable only via settings) — out of scope; listed for awareness.