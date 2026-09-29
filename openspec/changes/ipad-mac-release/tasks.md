## 1. Remove Catalyst

- [ ] 1.1 Set `SUPPORTS_MACCATALYST = NO` and `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` in the app target's Debug and Release build configs in `TaskFlow.xcodeproj/project.pbxproj`
- [ ] 1.2 Grep the project for remaining `macosx`/Catalyst references (build settings, schemes, scripts) and confirm none resolve to a required Mac build
- [ ] 1.3 Clean build on an Apple-silicon Mac and confirm "My Mac (Designed for iPad)" appears as a run destination
- [ ] 1.4 Verify entitlements still apply after the config change (iCloud container `iCloud.com.samson.wednesday`, CloudKit service, aps-environment) and the app runs unchanged on iPhone/iPad simulators

## 2. Verify Designed-for-iPad Launch

- [ ] 2.1 Run the app via the "My Mac (Designed for iPad)" destination and confirm the window opens to a usable iPad-size layout with the sidebar, split view, and capture bar visible
- [ ] 2.2 Confirm local iPhone↔Mac sync testing still works on the Designed-for-iPad destination: create/edit/delete on iPhone sim surfaces on the Mac via the shared CloudKit container (replaces the removed Catalyst test vehicle)
- [ ] 2.3 Confirm Local Notifications still schedule and present on the Mac destination; confirm no crash from haptics/icon-badge APIs on macOS (`ProcessInfo.processInfo.isiOSAppOnMac` runtime path is hit safely)

## 3. iPad / Mac Basic-Polish Pass

- [ ] 3.1 Run the verification matrix and log findings: iPhone compact (baseline), iPad portrait + landscape (regular width, sidebar), iPad split-view compact, Mac Designed-for-iPad window at small and large sizes
- [ ] 3.2 Fix any capture-bar dock issues at regular width (e.g., `.frame(maxWidth: .infinity)` overflow) so it renders as a centered usable bar
- [ ] 3.3 Fix any sheet/presentation-detent issues on iPad and Mac (editor, list/group creation, date picker) so content is fully usable and unclipped
- [ ] 3.4 Fix any landscape / safe-area / fixed-width assumptions surfaced by the matrix (list detail, timeline rows, editor)
- [ ] 3.5 Set `NavigationSplitView` `columnVisibility` default behavior appropriate for iPad vs Mac (no side-by-side columns on a phone-width compressed window)
- [ ] 3.6 Confirm every interactive element is pointer/keyboard-usable on the Mac (rows, context menus, cells, capture bar) with no touch-only gestures blocking a flow; add `keyboardShortcut` only where a flow is otherwise unreachable
- [ ] 3.7 Confirm no iPhone-only regression: iPhone compact flows behave identically to the pre-change App Store build

## 4. Launch-Behavior Configuration

- [ ] 4.1 Leave `UISupportsTrueScreenSizeOnMac` and `UILaunchToFullScreenByDefaultOnMac` unset in `TaskFlow/Info.plist` and document the decision in `decisions.md` (windowed resizeable iPad-size window is correct for a productivity app)
- [ ] 4.2 Add the launch-behavior decision to `decisions.md` alongside the designed-for-iPad decision (one decision record: "Adopt Designed-for-iPad Mac support; remove Mac Catalyst" including the Apple-silicon-only tradeoff and the interim Catalyst history)

## 5. Distribution (manual / external)

- [ ] 5.1 App Store Connect — confirm supported devices incursion iPad (devices list) and add iPad-only screenshots and any needed iPad listing metadata
- [ ] 5.2 App Store Connect — Pricing and Availability: check "Make this app available" under "iPhone and iPad Apps on Apple Silicon Macs"
- [ ] 5.3 App Store Connect — click "Verify Compatibility" after testing on Apple-silicon Mac, removing the "Not verified for macOS" label
- [ ] 5.4 Submit a TestFlight build and install/verify it on an Apple-silicon Mac, an iPad, and an iPhone before release
- [ ] 5.5 Confirm no Catalyst build is uploaded that would replace the Designed-for-iPad Mac offering

## 6. Verification & Docs

- [ ] 6.1 Run the full unit + UI test suite (in-memory, `.none` CloudKit) and confirm it passes unchanged after the Catalyst removal
- [ ] 6.2 Run the manual device matrix checklist from 3.1 and record results (or fix and re-verify until green)
- [ ] 6.3 Record the designed-for-iPad adoption decision in `decisions.md` (Apple-silicon-only, no compiled Mac app, single iOS binary, release gates in App Store Connect)
- [ ] 6.4 Update `AGENTS.md` or the app mental-model doc only as needed to note the device strategy (iPhone + iPad + Apple-silicon Mac via Designed-for-iPad); do not rewrite stale navigation specs as part of this change