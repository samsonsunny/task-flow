## Why

The Today and Tomorrow views have fast inline quick capture (tap `+`, type, enter, done), but Upcoming and List views lack this. Upcoming has multiple CTAs that open the full editor sheet, and ListDetailView's `+` also opens the sheet — both force the user into a heavy modal for simple task entry. This change brings the lightweight inline capture pattern to all views.

## What Changes

- **Upcoming view**: All existing "Add Reminder" CTAs (per-day buttons, day headers, empty day rows, month sub-section day activators) now trigger an inline text field within that section instead of opening the full editor. Only one inline field active at a time. Committing creates a task with that day's date. The chevron button still opens the full editor with the date pre-filled. The floating `+` button continues to open the full editor (no change).
- **ListDetailView**: The floating `+` button now triggers an inline text field at the top of the list (same pattern as Today/Tomorrow) instead of opening the editor directly. Committing creates a task assigned to the current list with no date. The chevron button opens the full editor with the list pre-filled.

## Capabilities

### New Capabilities
- `upcoming-inline-capture`: Per-day inline quick capture in Upcoming view — all existing CTAs (add reminder buttons, headers, empty rows, month sub-sections) activate an inline text field contextual to that day
- `list-inline-capture`: Inline quick capture in ListDetailView — floating `+` reveals an inline text field at the top of the list

### Modified Capabilities
- `contextual-task-creation`: The single top-of-list quick capture row no longer applies to the Upcoming segment (replaced by per-day captures). The "Quick capture row" requirement needs to be scoped to non-upcoming segments only.

## Impact

- `ReminderSegmentDetailView.swift` — replace `isQuickCapturing` (Bool) with `activeCaptureDate: Date?` state; convert all CTA activations to set active date instead of opening sheet; conditional rendering of inline field per section
- `ListDetailView.swift` — add `isQuickCapturing`, `quickCaptureText`, `isQuickCaptureFocused` state; floating `+` button triggers inline row; commit creates task with current list and no date
- Both views retain the chevron → full editor path
