## Why

The Schedule action in the reminder row context menu only offers a date-only picker, while the full ReminderEditorView supports both date and time pickers with toggles. Users cannot set a specific time when scheduling from the context menu, forcing them to open the full editor. Adding time picking with date/time toggling brings the Schedule action in line with the new reminder experience.

## What Changes

- Replace the date-only picker in `TaskScheduleDatePickerSheet` with date + time toggles and inline expandable pickers (matching `ReminderEditorView`'s schedule section)
- Allow users to toggle date on/off and time on/off in the sheet
- Auto-enable date when time is enabled (matching existing behavior in ReminderEditorView)
- Preserve existing task's dueDate when opening the schedule sheet; allow clearing it via toggle
- Update the sheet's title and layout to accommodate the new controls

## Capabilities

### New Capabilities
- `schedule-picker-date-time`: Date and time toggling with inline pickers in the context menu schedule sheet

### Modified Capabilities
- *(none — no existing specs have requirement changes; only the UI component changes)*

## Impact

- `TaskScheduleDatePickerSheet.swift`: Rewritten UI to support date/time toggles and inline pickers
- `ReminderSegmentDetailView.swift`: Updated sheet binding to support optional date (nil when toggled off), and time component
- No changes to data model, persistence, or other features
