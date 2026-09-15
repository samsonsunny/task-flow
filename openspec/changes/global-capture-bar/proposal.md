## Why

The Lists overview ("My Lists") is a capture dead-end. Because capture-bar ownership is per-destination (`CaptureHost`), and `lists-sidebar-split`'s Decision 3 deliberately hid the bar from the overview, a user browsing lists must first navigate into a day or a list before they can capture anything. Capture should be possible from any surface without pre-navigating.

## What Changes

- **One shared capture brain:** `CaptureBarViewModel` becomes app-wide, owned by `MainTabView` — a single minute-aligned timer, a single commit path, and the draft text lifted into the VM so both mounted bars render the same in-flight capture state.
- **Capture bar on the Lists overview:** the sidebar column gains its own capture bar mount with a new `CaptureTarget.inbox` default (assigned to the default Inbox list, undated). The detail column keeps its current per-destination target behavior. Exactly one bar is visible on compact (iPhone / iPad-compatibility) layouts; the sidebar mount is gated to compact size class so a future native iPad shows only the detail bar.
- **`CaptureHost` decomposes:** VM/timer/pending-date wiring moves to `MainTabView`; `CaptureTarget` gains an `.inbox` case. The old `testCaptureBarAbsentOnSidebar` contract is inverted.
- **Supersedes** `lists-sidebar-split` Decision 3 ("No capture bar on the Lists overview") — the overview now has a task surface to add to (Inbox, undated).

## Capabilities

### New Capabilities

- *(none)*

### Modified Capabilities

- `quick-capture`: Replaces the "capture bar presence is surface-aware" requirement inherited from `lists-sidebar-split` (bar only on task surfaces, explicitly absent from the Lists overview). The bar now SHALL appear on every surface including the Lists overview, target the default Inbox list undated there, and back every visible bar with one shared, app-wide capture state.

## Impact

- `TaskFlow/Features/MainTabView.swift` — owns the single `CaptureBarViewModel` + minute timer; mounts the sidebar capture bar (compact-gated) and the detail column's per-destination bar; absorbs `pendingCaptureDate`/`pendingCaptureFocus` consumption; detail `NavigationStack` folds back into the detail switch (with an optional thin wrapper).
- `TaskFlow/Views/Components/CaptureBarViewModel.swift` — adds `.inbox` full-run resolution (`dueDate = nil`, default Inbox list); holds shared draft `text`.
- `TaskFlow/Views/Components/CaptureBar.swift` — binds text to the shared VM instead of local `@State`.
- `TaskFlow/Views/Components/CaptureHost.swift` — removed (or reduced to a bare `NavigationStack` wrapper with no capture responsibilities).
- `TaskFlow/Features/Lists/ListView.swift` — unchanged logic; bar mounts around it in `MainTabView`.
- `TaskFlowUITests/TaskFlowUITests.swift` — `testCaptureBarAbsentOnSidebar` becomes `testCaptureBarPresentOnSidebar` (capture on overview commits undated to Inbox); existing detail-capture and focus tests revalidated.
- `AppState` — unchanged mechanically (signals already global); consumption moves to `MainTabView`.