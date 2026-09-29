# app-mental-model

## Purpose

Define the two-axis product mental model (attention vs. home) that the app’s navigation, organization, and capture behavior build on.

## MODIFIED Requirements

### Requirement: Navigation

The app SHALL expose a single `NavigationStack` as its only navigation surface, rooted at Home. There SHALL be no bottom tab bar, no sidebar, and no secondary navigation container. The home axis SHALL be surfaced on Home as a switch between the two areas; the attention axis SHALL be surfaced as Today / Tomorrow / Upcoming screens pushed from Home's summary block.

| Surface | Purpose | Content |
|---|---|---|
| Home (root) | The area, fully visible | Capture bar plus the selected area's lists and their tasks, grouped by list |
| Today (pushed) | Attention now | Selected area's tasks due today or overdue (dated subtasks included, flat) |
| Tomorrow (pushed) | Attention next | Selected area's tasks due tomorrow (dated subtasks included, flat) |
| Upcoming (pushed) | Coming in future | Selected area's tasks due D+2 onward (dated subtasks included, flat) |
| List detail (pushed) | One list | A single list's tasks |
| Completed (pushed) | Archive | Recently completed tasks |

#### Scenario: Time screens split the attention axis
- **WHEN** the user opens Today, Tomorrow, or Upcoming
- **THEN** each screen SHALL show only the selected area's tasks whose due date falls in that screen's range

#### Scenario: Home holds the home axis
- **WHEN** the user is at the root of the navigation stack
- **THEN** the app SHALL show the selected area's capture bar and its lists with their tasks, grouped by list

#### Scenario: No secondary navigation container exists
- **WHEN** the app runs
- **THEN** the view hierarchy SHALL contain exactly one `NavigationStack`
- **AND** SHALL NOT contain a bottom tab bar, a sidebar, or a `NavigationSplitView`

### Requirement: Default capture target

The default neutral capture target SHALL be the Inbox bucket of the **currently selected area**, resolved by pointer (`group.defaultList`), never by a positional fallback to the first group. There is no single global "Inbox" list; "Inbox" is a per-area concept. The selected area SHALL be visible in the navigation bar at the moment of capture, so the default target is never implicit.

#### Scenario: Default capture lands in the selected area's bucket
- **WHEN** the user captures a task with no explicit list selected
- **THEN** the task SHALL be assigned to the selected area's Inbox bucket

#### Scenario: Capture follows the area switch
- **WHEN** the user switches the selected area to Personal
- **AND** captures a task
- **THEN** the task SHALL be assigned to Personal's Inbox bucket

#### Scenario: No positional fallback is used
- **WHEN** the user captures a task
- **THEN** the resolver SHALL NOT substitute the first group's bucket when a different area is selected

#### Scenario: Empty store resolves to seeded Work area
- **WHEN** the user captures a task and no groups exist
- **THEN** the default Work and Personal areas SHALL be created and locked
- **AND** the task SHALL be assigned to the Work area's Inbox bucket

## REMOVED Requirements

### Requirement: Later tab

**Reason**: The Later tab no longer exists. Root navigation is a single `NavigationStack` rooted at Home, and lists are surfaced as sections on Home scoped to the selected area rather than as an organisational list-of-lists on a dedicated tab.

**Migration**: Home lists every list in the selected area, with that area's Inbox bucket pinned first. Tapping a list pushes `ListDetailView`. The invariants previously expressed here — every list belongs to an area, and every area has a protected Inbox bucket first in its section — are retained in `home-surface` (Home lists the selected area's tasks grouped by list, Inbox bucket pinned first) and `area-locking` (the store contains exactly two locked areas, each owning an Inbox bucket).

## ADDED Requirements

### Requirement: Axis selectors are explicit

The two axes SHALL be selected through two distinct, always-visible controls rather than through sibling navigation surfaces: the area switcher in the navigation bar selects the home axis, and a time screen selects the attention axis. At every moment the app SHALL make the current home-axis selection and the current attention-axis selection legible. The area selection SHALL be session-scoped, SHALL NOT be persisted, and SHALL default to Work on every launch.

#### Scenario: The two selectors are never confused
- **WHEN** the user is on the Today screen
- **THEN** the attention axis is selected by the screen itself (Today)
- **AND** the home axis remains selected by the area switcher inherited from the root

#### Scenario: Home selection defaults to Work each launch
- **WHEN** the user relaunches the app
- **THEN** the Work area SHALL be selected
- **AND** the app SHALL NOT restore the area viewed in the previous session

#### Scenario: Area scoping never hides deadlines without disclosure
- **WHEN** the user views a time screen scoped to one area
- **AND** the other area has incomplete tasks due today or overdue
- **THEN** the app SHALL disclose those tasks through a cross-area nudge rather than omitting them silently
