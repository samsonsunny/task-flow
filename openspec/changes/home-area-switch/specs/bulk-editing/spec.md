# bulk-editing

## Purpose

Define multi-select mode on task list screens: entering/exiting selection, the visual affordances that replace normal row interactions, and the bottom toolbar's bulk actions (Date, Move, Tag, Complete, Delete).

Consolidates (2026-08): `bulk-selection`, `bulk-operations`.

## MODIFIED Requirements

### Requirement: Enter selection mode via ellipsis menu

The system SHALL provide a "Select Items" option as the first item in the ellipsis (⋯) toolbar menu on all task list screens. Tapping "Select Items" SHALL enter selection mode. On Home, this menu SHALL also contain "Completed" and "Settings" below the "Select Items" entry.

#### Scenario: Select Items appears in ellipsis menu on Home
- **WHEN** the user is on Home
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item
- **AND** "Completed" and "Settings" SHALL appear below it

#### Scenario: Select Items appears in ellipsis menu on time screens
- **WHEN** the user is on the Today, Tomorrow, or Upcoming screen
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

#### Scenario: Select Items appears in ellipsis menu on ListDetailView
- **WHEN** the user is viewing a specific list (ListDetailView)
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

#### Scenario: Select Items appears in ellipsis menu on Completed screen
- **WHEN** the user is viewing the Completed screen
- **AND** the ellipsis menu is opened
- **THEN** "Select Items" SHALL appear as the first menu item

### Requirement: Quick capture disabled in selection mode

The capture bar and all inline capture functionality SHALL be hidden during selection mode, and the bottom bulk toolbar SHALL replace it.

#### Scenario: Capture bar not shown during selection
- **WHEN** the user is in selection mode
- **THEN** the capture bar SHALL NOT be visible
- **AND** no capture affordance SHALL occupy the bottom of the screen
- **AND** the bulk toolbar SHALL occupy that position instead

### Requirement: Move action in bottom toolbar

The bottom toolbar SHALL include a Move action (folder icon) that opens a submenu listing all available reminder lists, grouped by area, with each area's Inbox bucket first. The submenu SHALL list lists from **both** areas regardless of the selected area, so a bulk move may cross the Work/Personal boundary.

#### Scenario: Move submenu shows all lists
- **WHEN** the user taps the Move button in the bottom toolbar
- **THEN** a submenu SHALL appear listing all available reminder lists grouped by area

#### Scenario: Move applies to all selected tasks
- **WHEN** the user selects a list from the Move submenu
- **AND** 3 tasks are selected
- **THEN** all 3 tasks SHALL be moved to the selected list
- **AND** the selection mode SHALL remain active

#### Scenario: Bulk move may cross areas
- **WHEN** the user has Work tasks selected and bulk-moves them to a Personal list
- **THEN** every selected task SHALL have its `reminderList` set to that Personal list
- **AND** each task SHALL appear under Personal on Home
- **AND** no other property on those tasks SHALL be modified

## REMOVED Requirements

### Requirement: Floating add button hidden in selection mode

**Reason**: There is no floating add button in the app. The requirement is dead as written.

**Migration**: The live concern it expressed — a creation affordance competing with the bulk toolbar — is now specified in "Quick capture disabled in selection mode": the capture bar is hidden and the bulk toolbar takes the bottom slot.
