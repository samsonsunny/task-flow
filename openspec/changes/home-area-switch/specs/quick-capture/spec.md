# quick-capture

## Purpose

Define how tasks are captured across all contexts: the shared capture bar with its explicit destination chip, per-segment date context, and hand-off to the full editor.

Consolidates (2026-08): `contextual-task-creation`, `list-inline-capture`, `upcoming-inline-capture`.

## MODIFIED Requirements

### Requirement: Editor still available for full detail

The capture bar SHALL provide a detail disclosure control that opens the full editor with the same contextual defaults that committing the field would apply. The editor SHALL be reachable without a floating add button.

#### Scenario: Open editor from the capture bar
- **WHEN** the user taps the detail disclosure control on the capture bar
- **THEN** the full editor opens
- **AND** the destination list and any segment date are pre-filled consistently with the bar's own target

#### Scenario: Editor is reachable from a task row
- **WHEN** the user taps a task row on Home or in a list detail
- **THEN** the full editor opens for that task

### Requirement: Overview capture targets the first group's bucket

The capture bar's target SHALL always be an explicit, visible list, and SHALL default to the Inbox bucket of the currently selected area, resolved by pointer, with no `dueDate`. The bar SHALL render a target chip naming that destination. If the store has no areas yet, the resolver SHALL create the locked Work/Personal areas and target Work's bucket. The resolver SHALL NOT fall back to the first group by sort order when a different area is selected.

#### Scenario: Capture on Home creates an undated bucket task
- **WHEN** the user types a task title in Home's capture bar and submits
- **THEN** a new `TaskItem` is created with `reminderList` set to the selected area's Inbox bucket
- **AND** `dueDate` is `nil`

#### Scenario: Capture in an empty store seeds areas first
- **WHEN** the user captures on Home and no groups exist
- **THEN** the resolver SHALL create the locked Work/Personal areas with buckets
- **AND** the captured task SHALL be assigned to the Work Inbox bucket

#### Scenario: Capture follows the area switch
- **WHEN** the user switches to Personal and then captures on Home
- **THEN** the task SHALL be assigned to Personal's Inbox bucket
- **AND** the target chip SHALL read as Personal's bucket

#### Scenario: Destination is always visible before capture
- **WHEN** the user is about to type in the capture bar
- **THEN** the bar SHALL display a chip naming the destination list
- **AND** no capture path SHALL leave the destination implicit

#### Scenario: User can retarget the destination
- **WHEN** the user opens the target chip's menu
- **THEN** every list in every area SHALL be offered, grouped by area
- **AND** selecting one SHALL make it the destination for subsequent captures

### Requirement: Capture target resolves from the selected surface

The capture bar's target SHALL resolve from the active surface and SHALL be stated on the bar in every case:

| Surface | Destination | Date |
|---|---|---|
| Home | Selected area's Inbox bucket | none |
| Today | Selected area's Inbox bucket | today |
| Tomorrow | Selected area's Inbox bucket | tomorrow |
| Upcoming | Selected area's Inbox bucket | none, or the tapped day's date from the per-day control |
| List detail | That list | none |

#### Scenario: Capture on a time segment assigns the segment date
- **WHEN** the user captures a task on the Today screen with Personal selected
- **THEN** the task is created with `dueDate = start of today`
- **AND** the task is assigned to Personal's Inbox bucket

#### Scenario: Capture in a list assigns to that list
- **WHEN** the user captures a task while viewing a specific list's tasks
- **THEN** the task is created with no `dueDate`
- **AND** the task is assigned to the viewed list

#### Scenario: Capture inside an area's bucket assigns to that bucket
- **WHEN** the user captures a task while viewing an area's Inbox bucket
- **THEN** the task is created with no `dueDate`
- **AND** the task is assigned to that bucket

#### Scenario: Upcoming capture does not pre-fill a date by default
- **WHEN** the user captures a task from the Upcoming screen's bar
- **THEN** the task SHALL be created with no `dueDate`
- **AND** the bar's date hint SHALL make the absence of a date explicit

## REMOVED Requirements

### Requirement: Context-aware + button

**Reason**: There is no floating add button. Its context-aware defaults are now owned by the capture bar, which resolves its target from the selected area and active surface and shows the destination on the bar. The `+` affordance is also the specific cause of the reported confusion — stacked next to a field reading "Add a task…", it made the bar read as list creation.

**Migration**: The capture bar is the single creation control on every surface. Its destination is always visible on the bar, so the same defaults are applied with no hidden state.

### Requirement: Quick capture row

**Reason**: The reveal-on-tap inline field was coupled to the floating `+`. With no `+`, the capture bar is always present, so there is nothing to reveal. The dead `QuickCaptureRow` component is removed.

**Migration**: Use the always-present capture bar; it accepts typed text, commits on return, and clears while remaining focused for rapid successive entry.

### Requirement: Inline quick capture in ListDetailView

**Reason**: Superseded by the capture bar rendered on the list detail surface, which targets that list.

**Migration**: The capture bar in list detail assigns to the viewed list and creates undated tasks.

### Requirement: Inline quick capture in Today/Tomorrow views

**Reason**: Superseded by the capture bar rendered on the time screens, which targets the selected area's bucket and applies the segment's date.

**Migration**: The capture bar on Today and Tomorrow shows a date hint naming the date it will apply.

### Requirement: Inline quick capture in Upcoming views

**Reason**: Superseded by the capture bar on the Upcoming surface. The per-day section-level field is removed along with the `+`-triggered reveal.

**Migration**: Upcoming keeps a per-day "Add Reminder" control that opens the full editor with that day's date pre-filled.

### Requirement: Shared QuickCaptureRow component

**Reason**: `Views/Components/QuickCaptureRow.swift` has zero references in the app, tests, and UI tests, and its spec is the reason it exists. With the inline field gone, the component is dead code.

**Migration**: None. The capture bar is the single shared capture surface; list detail and time screens all instantiate it with a different target.

### Requirement: Per-day inline quick capture in upcoming view

**Reason**: The per-day inline text field, its tap-to-activate targets, the single-active-field rule, swipe-to-cancel, and the "move the field between sections" behaviour all exist to serve an inline field that no longer exists. The Upcoming surface's per-day editor hand-off is retained.

**Migration**: Tapping "Add Reminder" in an Upcoming day section opens the full editor with `initialDate` set to that day and the destination pre-filled from the capture bar's target.
