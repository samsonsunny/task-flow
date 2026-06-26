## Why

`ReminderSegmentDetailView` is the largest file in the project at 714 lines. It handles filtering, sorting, grouping, quick capture, completion, scheduling, and deletion across 5 different segments (Today, Tomorrow, Upcoming, Later, Overdue). Business logic is embedded in private computed properties and methods that cannot be unit tested in isolation. A ViewModel extraction makes the segment logic testable and the view manageable.

## What Changes

- Create `ReminderSegmentViewModel` as an `@Observable` class owning all business logic and presentation state for segment detail screens
- `ReminderSegmentDetailView` becomes a thin consumer: observes VM state, delegates all mutations to the VM
- Move to VM: segment filtering/sorting/grouping, quick capture, completion toggling, scheduling, rescheduling, deletion, overdue state, and timer-based refresh
- View retains only: `@Query` for fetching data, pure-UI state, and rendering

## Capabilities

### New Capabilities
- `reminder-segment-view-model`: ViewModel for `ReminderSegmentDetailView` owning segment filtering/sorting/grouping, quick capture, completion lifecycle, scheduling, rescheduling, and overdue management across all 5 segments

### Modified Capabilities
*None — existing specs are implementation details unaffected by MVVM extraction.*

## Impact

- **New file**: `TaskFlow/Features/Reminders/ViewModels/ReminderSegmentViewModel.swift`
- **Modified**: `ReminderSegmentDetailView.swift` — reduced from ~714 lines to ~250 lines of pure view code
- **Modified**: `TodayTabView.swift` — may pass `modelContext` or adjust initialization if needed
- **All existing specs** remain unchanged — pure refactor with no behavioral changes
