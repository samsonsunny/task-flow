## ADDED Requirements

### Requirement: Single iOS binary distributes on iPhone, iPad, and Apple-silicon Macs
The system SHALL build one iOS/ipados binary (bundle ID `com.samson.wednesday`, device family iPhone+iPad) that distributes to iPhone, iPad, and Apple-silicon Macs, with Mac delivery happening through the Designed-for-iPad mechanism rather than a compiled macOS build.

#### Scenario: App is offered on Apple-silicon Macs as Designed-for-iPad
- **WHEN** the app is built for the iPhone+iPad device family
- **THEN** the same iOS binary is offerable in the Mac App Store on Apple-silicon Macs labeled "Designed for iPad"

#### Scenario: No Mac Catalyst build exists
- **WHEN** the app target configures its platforms
- **THEN** `SUPPORTS_MACCATALYST` is `NO` and `macosx` is not present in `SUPPORTED_PLATFORMS`

### Requirement: Mac availability is enabled and verified in App Store Connect
The system distribution SHALL have Apple-silicon-Mac availability enabled and compatibility verified in App Store Connect as a release gate, and SHALL be tested via TestFlight on Mac before release.

#### Scenario: Deliverable release gate
- **WHEN** a release build is prepared for submission
- **THEN** "Make this app available" under Apple Silicon Mac availability is checked and compatibility is verified, with a TestFlight build tested on an Apple-silicon Mac

#### Scenario: Catalyst build is not submitted as the Mac offering
- **WHEN** the app is submitted
- **THEN** no macOS (Catalyst) build exists in App Store Connect that would replace or block the Designed-for-iPad offering

### Requirement: Unsupported environments degrade gracefully
The system SHALL document and accept that Intel Macs cannot run the app, and SHALL not advertise Mac support beyond Apple-silicon hardware.

#### Scenario: Intel Mac user searches
- **WHEN** a user on an Intel Mac searches for the app in the Mac App Store
- **THEN** the app is not offerable, matching the documented Apple-silicon-only limitation