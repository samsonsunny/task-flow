## ADDED Requirements

### Requirement: Core flows function on iPad in all supported orientations and widths
The system SHALL make all core user flows (Today/Tomorrow/Upcoming, Later lists, quick capture, editor, completion) fully usable on iPad in portrait and landscape and in both regular and compact width classes, without content clipping or unreachable controls.

#### Scenario: Navigation on iPad regular width
- **WHEN** the app runs on an iPad in a regular horizontal size class
- **THEN** the sidebar with time pages and lists is shown via `NavigationSplitView`, and every destination is reachable without swiping

#### Scenario: Navigation on iPad compact width
- **WHEN** the app runs on an iPad in a compact horizontal size class (e.g., split view)
- **THEN** navigation collapses to the phone-style flow and every destination remains reachable

#### Scenario: Editor and picker sheets on iPad
- **WHEN** the user opens the editor, list/group creation, or date picker on an iPad
- **THEN** the presented sheet adapts to the environment and its content is fully usable with no clipped controls

### Requirement: Core flows function on Apple-silicon Mac via Designed-for-iPad
The system SHALL keep every interactive element and task flow usable with a pointer and keyboard when run on an Apple-silicon Mac through the Designed-for-iPad environment, with no interaction gated behind a touch-only gesture.

#### Scenario: Click to complete a task on Mac
- **WHEN** the user clicks a task row's completion control on the Mac
- **THEN** the task completes exactly as it does on iPhone

#### Scenario: All rows and menus are clickable
- **WHEN** the user runs the app on the Mac
- **THEN** every row, context menu, sheet, and the capture bar respond to a pointer click without requiring touch

### Requirement: App stays functional in a resizeable Mac window
The system SHALL render correctly in the resizeable Designed-for-iPad window without fixed iPhone-width assumptions, reflowing layout and keeping text and controls unclipped.

#### Scenario: Window resize reflows layout
- **WHEN** the user resizes the app window on the Mac
- **THEN** content reflows with no clipped rows, hidden controls, or layout breakage

#### Scenario: Capture bar remains usable
- **WHEN** the capture bar is docked at the bottom on a wide Mac window
- **THEN** it remains a centered, usable bar rather than stretching phonescale content edge-to-edge in a broken way

### Requirement: iPhone behavior is preserved
The system SHALL not regress the iPhone compact-width experience while adding iPad/Mac support.

#### Scenario: iPhone flows remain byte-identical
- **WHEN** the existing iPhone UI flows run on a phone-wide compact layout
- **THEN** behavior and layout match the pre-change releases