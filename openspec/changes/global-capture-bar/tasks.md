## 1. ViewModel: shared state + inbox target

- [x] 1.1 Add `var text: String = ""` to `CaptureBarViewModel` and make draft text bindable (remove nothing else yet)
- [x] 1.2 Add `case inbox` to `CaptureTarget` in `Views/Components/CaptureHost.swift`
- [x] 1.3 Update `CaptureBarViewModel.resolveTargetDate(for:overrideDate:)` so `.inbox` returns `nil` (undated) without hitting the segment branch
- [x] 1.4 Update `CaptureBarViewModel.resolveTargetList(for:)` so `.inbox` resolves to the default Inbox list (falls through the existing default path, created if missing)
- [x] 1.5 Confirm `commit(text:notes:target:overrideDate:)` compiles for `.inbox` and routes through `resolveTargetDate`/`resolveTargetList`

## 2. CaptureBar binds to shared view model

- [x] 2.1 Change `CaptureBar` to accept the shared `CaptureBarViewModel` (or `text` binding + target/commit callbacks)
- [x] 2.2 Bind the text field's `@State private var text` to the shared VM's `text` instead of local state
- [x] 2.3 Keep `@FocusState` per-instance (UI-only state stays in the view)
- [x] 2.4 Clear `isFocusingCapture` when a mount takes focus or commits, so revealing the sidebar later doesn't re-nag-focus

## 3. MainTabView owns the capture surface

- [x] 3.1 Move `CaptureBarViewModel` ownership and the minute-aligned timer from `CaptureHost` into `MainTabView` (create/destroy with the split view's `onAppear`/`onDisappear`)
- [x] 3.2 Remove the `.id(appState.pendingCaptureDate)` reset trick; handle `pendingCaptureDate` with `vm.text = ""` + a focus request in `MainTabView`
- [x] 3.3 Consume `appState.pendingCaptureFocus` and `hasAutoFocusedOnce` once in `MainTabView` (not per host)
- [x] 3.4 Add a single **root-level** bar as a sibling below the entire `NavigationSplitView` (one `VStack(spacing: 0)`: split view above, bar below) — never inside or inset on any navigation container
- [x] 3.5 Resolve the bar target in `MainTabView`: compact + sidebar frontmost → `.inbox`; else the `selectedDestination`'s `.segment` / `.list`; track sidebar frontmost via sidebar `.onAppear`/`.onDisappear`
- [x] 3.6 Fold the detail `NavigationStack` back into the detail switch (via a small helper or inline), and delete `CaptureHost` (or reduce it to a bare `NavigationStack` wrapper with no capture responsibilities)

## 4. Tests

- [x] 4.1 Invert `testCaptureBarAbsentOnSidebar` → `testCaptureBarPresentOnSidebar` in `TaskFlowUITests.swift`: bar exists after `openSidebar`, capture + submit, open Inbox detail, assert the undated task landed there
- [x] 4.2 Keep `testCaptureBarPresentInListDetail`; verify both detail and overview bar mounts share the same accessibility identifier and resolve via `firstMatch`
- [x] 4.3 Revalidate autofocus-once and `pendingCaptureDate` (Upcoming day-header) UI tests under the single shared VM
- [x] 4.4 Add/verify a draft-continuity check if feasible: type text in the detail bar, reveal the sidebar, assert the text persists in the overview bar

## 5. Verification

- [x] 5.1 Build the app for iOS simulator (`xcodebuild build`) and fix any compile errors
- [ ] 5.2 Run the UI test suite and confirm all capture-bar tests pass
- [ ] 5.3 Run the unit test suite (ViewModel/`DraftTests` etc.) and confirm no regressions
- [ ] 5.4 Manually sanity-check on simulator: capture from Today, reveal sidebar, capture again (Inbox, undated), confirm list detail shows the overview-captured task