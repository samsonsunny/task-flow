## Context

Wednesday Calendar (internal "TaskFlow") is a SwiftUI + SwiftData app that today is verified and released for iPhone. The target already declares iPhone+iPad device family (`TARGETED_DEVICE_FAMILY = "1,6"`) and iPad orientations, and navigation already adapts via `NavigationSplitView` + sidebar (`MainTabView.swift`). iCloud sync (commit `f215627`, 26.9.23) wires a single private CloudKit container behind bundle ID `com.samson.wednesday`, which makes cross-device use meaningful.

A Mac Catalyst build was enabled (commit `8fec264`) as a temporary vehicle for local iPhone↔Mac sync testing. Catalyst conflicts with the platform's zero-cost Mac path for iOS apps: on the App Store, a Catalyst (macOS) build replaces the "Designed for iPad" availability for the same app, so this app must choose one. The interim Catalyst config is the only thing standing between the current build and the designed-for-iPad offering.

## Goals / Non-Goals

**Goals:**

- Ship one iOS binary that runs on iPhone, iPad, and Apple-silicon Macs.
- Remove the Mac Catalyst config so the App Store surfaces Designed-for-iPad.
- Verify and minimally polish the core flows so iPad and Mac users are not blocked by touch-only or iPhone-width-only interactions.
- Keep schema V10, CloudKit wiring, MVVM conventions, previews/tests, and the weekly release cadence untouched.

**Non-Goals:**

- A compiled native macOS app or a Mac target (rejected by decision; see proposal).
- Apple Pencil, Stage Manager, and explicit multiwindow/Scene support (single window for v1).
- Re-architecting navigation or adding new iPad-exclusive features.
- Fixing pre-existing spec/code drift (`app-mental-model`, `tab-bar-navigation`) beyond what this change needs for clarity.
- Keyboard-shortcut menus beyond what SwiftUI inherits automatically.

## Decisions

### D1: Remove Catalyst; adopt Designed-for-iPad
Delete Catalyst from the app target: set `SUPPORTS_MACCATALYST = NO` and `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` in both Debug and Release app configs (`project.pbxproj`). The Designed-for-iPad run destination appears automatically on Apple-silicon Macs; it needs no separate target ("destination", not target — Xcode 14+). Local iPhone↔Mac sync testing continues via the "My Mac (Designed for iPad)" destination in the same iOS runtime, so CloudKit `.private` container sync behavior is unchanged.

- **Why over keeping Catalyst:** Catalyst recompiles for the macOS SDK, exports `ProcessInfo.isiOSAppOnMac = false`, adds a second platform to test/maintain, and blocks the App Store's designed-for-iPad availability. Designed-for-iPad runs the identical iOS binary with zero added maintenance.
- **Alternative considered:** Keep Catalyst for Mac release and disable designed-for-iPad. Rejected: doubles platform maintenance for no user-visible win, and the team already confirmed Catalyst as temporary.
- **Tradeoff (accepted):** Intel Macs cannot run the app. Apple-silicon-only coverage is the agreed scope.

### D2: Do not set Mac launch-behavior plist keys
Leave `UISupportsTrueScreenSizeOnMac` and `UILaunchToFullScreenByDefaultOnMac` unset. The app is a productivity tool, not a game/media app; the compatible iPad-size resizeable window is the correct target shape.

- **Why:** true screen-size support exposes a pixel-density variant we would then have to verify across all views for zero benefit; fullscreen-by-default fights a task app's expected windowed behavior.

### D3: Polish driven by a verification matrix, not a rewrite
Run a defined device matrix and fix only what surfaces:
- iPhone (compact, portrait) — baseline, must stay byte-identical in behavior.
- iPad (regular portrait + landscape, sidebar shown; compact split view if applicable).
- My Mac (Designed for iPad) — pointer/keyboard, resizeable window, capture-bar dock, sheets.

Candidate watch-list (fix only if actually broken): capture-bar dock width on regular width (currently `frame(maxWidth: .infinity)`), half-sheet presentation detents on iPad/Mac (may want `.presentationDetents` centered vs full-screen), landscape safe areas, `NavigationSplitView` `columnVisibility` default, and any `UITest` argument handling. Every fix stays inside view/polish — no ViewModel or schema change.

### D4: Distribution is a manual, tracked process
App Store Connect work (iPad listing, Apple-silicon-Mac availability checkbox, compatibility verification, TestFlight) is external and manual. Its progress is tracked as tasks with explicit verification steps so it can be completed without code.

### D5: Single canonical record in decisions.md
Add one decision: "Adopt Designed-for-iPad Mac support; remove Mac Catalyst." It records the Apple-silicon-only tradeoff, the interim Catalyst history, and the constraint that this app cannot offer a compiled macOS build while relying on designed-for-iPad.

## Risks / Trade-offs

- [Intel Macs lose the ability to run the app] → Accepted and documented in `decisions.md` and the proposal; Intel is out of scope (Apple-silicon-only).
- [Catalyst removal breaks the local sync-test vehicle] → Mitigated by using the "My Mac (Designed for iPad)" destination, which runs in the same iOS runtime with the same private CloudKit container; verified in task 1.x before merge.
- [Designed-for-iPad surfaces untested iPhone-centric layouts (sheets, docked capture bar)] → Mitigated by the D3 verification matrix before release and a fix-only-what-breaks policy.
- [App Store Connect cannot offer both Catalyst and designed-for-iPad; leaving Catalyst on silently serves the wrong Mac build] → Mitigated by removing Catalyst as task 1 and flagging "make available on Apple-silicon Macs" as a mandatory release gate.
- [iCloud/CloudKit entitlements regress after signing-config edits] → Mitigated by confirming entitlements and the app's iCloud capability are untouchased, then verifying a clean build + run in the matrix.