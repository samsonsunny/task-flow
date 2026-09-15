## Context

The current navigation is a `NavigationSplitView` with a sidebar (lists) and a detail column (Today/Tomorrow/Upcoming or a selected list). Each destination wraps its content in a `CaptureHost`, which owns its own `NavigationStack`, `CaptureBarViewModel`, minute-aligned timer, and a `CaptureBar` attached via `.safeAreaInset(.bottom)`.

Because each destination has its own host, switching destinations tears down the entire capture surface: navigation depth lost, in-flight capture text lost, VM and timer recreated. `AppState.pendingCaptureDate` / `pendingCaptureFocus` exist solely as global signals to bridge per-host boundaries — plumbing whose only job is to patch around the non-global design.

The Lists overview (the sidebar column) has no `CaptureHost` at all, by design (Decision 3 of `lists-sidebar-split`). This makes the overview a capture dead-end.

## Goals / Non-Goals

**Goals:**
- One `CaptureBarViewModel` instance app-wide: one timer, one commit path, one shared in-flight draft.
- Capture bar visible on every surface, including the Lists overview — a single, always-present, bottom-docked bar.
- Overview capture targets the default Inbox list, undated (the mental-model staging area).
- Remove the per-host VM/timer/pending-date plumbing.
- Never animate the bar with push/pop or split-view column transitions.

**Non-Goals:**
- Supporting native iPad dual-column layouts (app is iPhone-only, `TARGETED_DEVICE_FAMILY = 1`).
- Changing the editor's sheet/push presentation or `CaptureBar` visual design.
- Changing Upcoming's per-day header fast-path capture or time segment targets.
- New "target chip" or inline target-switching UI on the overview bar.

## Decisions

### Decision 1: Shared `CaptureBarViewModel` owned by `MainTabView`

**Chosen:** `MainTabView` owns the single `CaptureBarViewModel` and the minute-aligned timer. The VM is created once in `onAppear` and lives for the app's lifetime.

**Rationale:**
- A single VM means one `text` binding — typed text persists across all surfaces and navigation states.
- One timer (rather than one per host) simplifies lifecycle and avoids drift.
- `pendingCaptureDate`/`pendingCaptureFocus` are consumed directly in `MainTabView`, eliminating bridging plumbing.

**Alternatives considered:**
- *Per-host VMs with shared state object*: re-introduces a coordinator layer. Less direct than one VM.
- *VM in `AppState`*: wrong ownership; `AppState` doesn't own view-level concerns.

### Decision 2: Root-level single bar — a true sibling below the entire `NavigationSplitView`

**Chosen:** A single `VStack(spacing: 0)` owned by `MainTabView`:
1. Top: `NavigationSplitView` (sidebar + detail columns)
2. Bottom: one `CaptureBar` bound to the shared VM

```
┌─ MainTabView ───────────────────────────────────────────────┐
│ VStack(spacing: 0)                                          │
│   ┌─ NavigationSplitView ─────────────────────────────────┐ │
│   │ sidebar: ListsSidebarView                             │ │
│   │ detail:   NavigationStack { Today/Lists/Upcoming }    │ │
│   └───────────────────────────────────────────────────────┘ │
│   CaptureBar (always this single bar, never duplicated)     │
└─────────────────────────────────────────────────────────────┘
```

The bar is **outside all navigation containers**. Push/pop animations, interactive back-swipe, split-view column transitions, and sidebar drawer drags all happen entirely inside the `NavigationSplitView` — the bar never participates and never moves. This is the exact "tab-bar docked" model: fixed at the bottom, content changes above it.

**Why not `safeAreaInset` on `NavigationStack`:** the inset content participates in the stack's push/pop transition on current SDKs — during a back-swipe the bar visibly slides out together with the dismissed page.

**Why not dual mount (one bar per column):** both columns' bars would animate with the split-view column transition on compact (sidebar ↔ detail push/pop), showing two bars during the animation. A single root bar is the only structure that stays fixed through every possible transition type.

**Alternatives considered:**
- *Dual mount (per-column sibling)*: works for push/pop within a stack but not for column transitions; causes two-bar duplication during compact collapsed sidebar reveals and returns.
- *`safeAreaInset` on the stack*: the bar animates with push/pop (observed in practice). Rejected.

### Decision 3: Overview capture target = `CaptureTarget.inbox`

**Chosen:** A new `CaptureTarget.inbox` case. `resolveTargetDate(for:)` returns `nil` (undated). `resolveTargetList(for:)` returns the default Inbox list (`ReminderDefaults.defaultListName`), creating it if needed.

**Rationale:** The mental model defines Inbox as "a staging area for new/uncategorized tasks." The Lists overview is the home-axis hub; capturing there without a pre-selected destination should land in the neutral home.

**Alternatives considered:**
- *Follow the highlighted selection*: still requires choosing a day/list — doesn't fix the dead-end.
- *Target chip picker on the bar*: more UI surface, unnecessary complexity for an overview; deferred.

### Decision 4: `CaptureHost` deleted; detail columns are bare `NavigationStack`s

**Chosen:** `CaptureHost.swift` is deleted entirely. Each detail destination is a plain `NavigationStack { content }` inside the `NavigationSplitView`'s `detail:` builder. No `.safeAreaInset` on the stack — the bar lives outside it.

The `.id(appState.pendingCaptureDate)` reset on the bar is replaced by `MainTabView` setting `vm.text = ""` + requesting focus when `pendingCaptureDate` changes.

**Rationale:** `CaptureHost`'s sole remaining job was wrapping content in a `NavigationStack`; that is now a one-liner in the detail switch. Removing it eliminates a redundant view layer and makes the data flow explicit.

### Decision 5: Draft text moves into the shared VM

**Chosen:** `CaptureBarViewModel` gains `var text: String`. `CaptureBar` binds to it instead of local `@State`.

**Rationale:** This is the minimal change that makes the bar feel like *one persistent bar* — text typed in Today persists across sidebar reveal, list switches, and push/pop.

**Alternatives considered:**
- *Keep `@State` in each mount*: breaks the "global" invariant: text typed in Today disappears on navigation, which is the exact behavior that feels disjointed.

### Decision 6: Target resolution uses sidebar lifecycle

**Chosen:** `MainTabView` tracks `isOverviewFrontmost` via `.onAppear`/`.onDisappear` on the `ListsSidebarView`. On compact, when the sidebar is frontmost, target = `.inbox`; when the detail is frontmost, target = the `selectedDestination`'s corresponding segment/list.

On regular width (iPad), the overview flag is ignored and target always = selection — both columns are visible, and overview capture going to the selected list is acceptable.

```swift
private var currentCaptureTarget: CaptureTarget {
    if horizontalSizeClass == .compact && isOverviewFrontmost {
        return .inbox
    }
    switch selectedDestination { ... }
}
```

**Rationale:** `NavigationSplitView` on compact drives sidebar visibility via its own push/pop (or overlay reveal); `.onAppear`/`.onDisappear` on the sidebar content tracks this lifecycle. No UIKit introspection needed.

**Alternatives considered:**
- *Track detail lifecycle instead*: same reliability, inverted — either works; sidebar chosen for clarity.
- *Hardcode .today default*: doesn't fix the dead-end when another list was last selected.
- *Clear `selectedDestination` on pop*: can't intercept the split view's pop gesture cleanly.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| `.onAppear`/`.onDisappear` on sidebar might not fire reliably during a mid-drag overlay reveal | At COMMIT time the drag has settled and the flag is accurate; the flag only matters at commit, not during drag. Flag is also compact-gated so iPad is unaffected. |
| Content no longer scrolls beneath the bar (docked, not floating) | Deliberate — this is the requested "tab-bar placement" behavior; matches the sticky, always-visible bar across all pages. |
| `CaptureBar.text` lift into VM slightly bends MVVM "UI-only state in view" rule | Text is draft state committed to the model, not a display-only focus/scroll offset. Justification is the shared-state requirement; `FocusState` stays per-view. |
| Future iPad layout: bar spans full width beneath both columns | Acceptable for iPhone-only app; root-level bar on iPad would be a single global bar, which is arguably correct behavior. |
| `isFocusingCapture` may re-focus the bar when revealing sidebar later in a session | Cleared in `CaptureBar.onAppear` after taking focus, or reset on commit; aligns with existing autofocus-once semantics. |