## Why

Reminders currently support only date-based deadlines with no time component. Users cannot set a specific time a reminder is due, limiting the app's usefulness for time-sensitive tasks. Adding an optional deadline time makes reminders more precise while keeping the interface minimal and the toggle-driven interaction consistent with the existing design language.

## What Changes

- Replace the current inline compact DatePicker in the schedule section with expandable inline date and time rows
- Add a date toggle that defaults to off when no date is set; when on (either by user toggle or by receiving an `initialDate` from the caller), shows the selected date as a subtitle on the date row
- Tapping the date row expands it inline with a date picker; collapsing after selection
- Add a time toggle that is only active when a date is set; when on, shows the selected time as a subtitle on the time row
- Tapping the time row expands it inline with a time picker; auto-select nearest rounded hour
- Disabling the date toggle automatically removes the time (time toggle detoggled)
- Stop normalizing `dueDate` to start of day in `ReminderDraftMapper` so the time component is preserved on save
- No schema migration needed — `dueDate` already stores a full `Date` including time components

## Capabilities

### New Capabilities
- `reminder-deadline-time`: Optional time component for reminder due dates with expandable inline date and time pickers and automatic time removal when date is disabled.

### Modified Capabilities

- *(none — no existing specs change)*

## Impact

- `TaskFlow/Features/Reminders/ReminderEditorView.swift`: Rewrite schedule section with expandable date/time rows
- `TaskFlow/Features/Reminders/ReminderDraft.swift`: Add `hasTime` tracking to draft state
- `TaskFlow/Models/TaskItem.swift` (ReminderDraftMapper): Stop stripping time from `dueDate` when time is enabled
- No schema or migration changes — `dueDate` field already supports time
- No UI test changes needed if existing date-only tests continue to work
