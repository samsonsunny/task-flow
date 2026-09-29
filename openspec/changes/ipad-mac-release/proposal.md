## Why

Wednesday Calendar is verified and released for iPhone only, even though the project already builds for iPad and iCloud sync (shipped 26.9.23) makes a device family valuable. A Mac Catalyst build was enabled as a temporary local sync-test vehicle, but Catalyst is the wrong long-term Mac strategy for a SwiftUI app: Apple serves the compiled Catalyst build on Mac, which **blocks** the "Designed for iPad" App Store offering for the same app. We want one iOS binary that runs on iPhone, iPad, and Apple-silicon Macs — reachable with zero extra code, via the designed-for-iPad mechanism.

## What Changes

- **Remove Mac Catalyst** from the app target (`SUPPORTS_MACCATALYST = NO`, drop `macosx` from `SUPPORTED_PLATFORMS`) so the Mac release path is Designed-for-iPad. (**BREAKING**: the Catalyst "My Mac" run destination disappears; local iPhone↔Mac sync testing moves to the "My Mac (Designed for iPad)" destination. Intel Macs are no longer a run target.)
- **Adopt Designed-for-iPad on Apple-silicon Macs**: verify the "My Mac (Designed for iPad)" destination builds/runs, and enable Mac availability in App Store Connect.
- **Basic iPad + Mac UX verification and polish**: run the full app matrix (iPhone, iPad portrait/landscape with split view, My Mac Designed-for-iPad) and fix surfaced issues (capture-bar dock, half-sheets vs centered sheets, landscape safe areas, sidebar column visibility). Core flows (Today/Tomorrow/Upcoming/Lists/Later, capture, editor, completion) must work with pointer/keyboard and no touch-only interactions.
- **Evaluate Mac launch-behavior plist keys** (`UISupportsTrueScreenSizeOnMac`, `UILaunchToFullScreenByDefaultOnMac`) and document the decision (default: not set — windowed resizeable iPad-size window is correct for a task app).
- **Distribution tasks (manual/external)**: iPad App Store listing, App Store Connect Apple-silicon-Mac availability + compatibility verification, TestFlight on Mac.
- **Decision records + docs**: `decisions.md` entry documenting the Designed-for-iPad strategy (Apple-silicon-only tradeoff) over Catalyst; fix the stale `app-mental-model`/`tab-bar-navigation` drift only where it blocks this change's clarity.
- **No schema, ViewModel, or iCloud changes.** V10 schema and CloudKit wiring are untouched; pre-existing specs/tests stay green.

## Capabilities

### New Capabilities

- `device-distribution`: The app distributes on iPhone and iPad via the iOS App Store and on Apple-silicon Macs via the Designed-for-iPad mechanism; Catalyst is not built, and Mac availability is enabled and verified in App Store Connect.
- `ipad-mac-basic-experience`: Core user flows function correctly on iPad (portrait/landscape, regular and compact width, split view) and inside the Designed-for-iPad window on Apple-silicon Macs, with no touch-only or iPhone-width-only interactions blocking usage.

### Modified Capabilities

<!-- No existing spec requirements change because of this work; the device-independent behavior specs remain as-is. -->

## Impact

- `TaskFlow.xcodeproj/project.pbxproj` — remove Catalyst from app-target Debug/Release configs; verify schemes and destinations.
- `TaskFlow/Info.plist` — evaluate (default: leave unset) `UISupportsTrueScreenSizeOnMac` / `UILaunchToFullScreenByDefaultOnMac`.
- SwiftUI views — targeted size-class / device-polish adjustments across `MainTabView`, capture bar, sheets, and list detail as surfaced by verification; no architectural changes.
- App Store Connect (manual, external) — supported devices, iPad screenshots, Apple-silicon-Mac availability + compatibility verification, TestFlight.
- `decisions.md` — new decision reversing the interim Catalyst stance.
- Verify no entitlement/signing regressions after Catalyst removal (same bundle ID `com.samson.wednesday`, iCloud capability stays).