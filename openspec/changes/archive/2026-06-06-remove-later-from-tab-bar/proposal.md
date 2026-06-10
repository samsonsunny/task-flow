## Why

The tab bar in `SmartFilterTabbedView` shows "Later" as a 4th tab because it iterates `ReminderSegment.allCases`. The sidebar already has a dedicated "Later" nav link, making the tab bar duplicate redundant and confusing. The tab bar should only show Today, Tomorrow, and Upcoming.

## What Changes

- **BREAKING**: Replace `ReminderSegment.allCases` with explicit whitelist `[.today, .tomorrow, .upcoming]` in `SmartFilterTabbedView`
- **BREAKING**: Update the `sidebar-navigation` spec: remove the requirement that `.later` be deleted from the `ReminderSegment` enum; add a requirement that the tab bar uses an explicit whitelist of 3 segments

## Capabilities

### New Capabilities

*(none)*

### Modified Capabilities

- `sidebar-navigation`: The tab bar in `SmartFilterTabbedView`/`FilterDetailView` SHALL show exactly three tabs (Today, Tomorrow, Upcoming) using an explicit segment whitelist, not `ReminderSegment.allCases`. The `.later` segment is removed as a tab bar entry. The `ReminderSegment` enum retains `.later` for sidebar and filtering use.

## Impact

- `App/ContentView.swift` — Line ~199: `ReminderSegment.allCases` → `[.today, .tomorrow, .upcoming]`
- `openspec/specs/sidebar-navigation/spec.md` — Replace the "ReminderSegment trimmed to 3 cases" requirement with correct language about tab bar whitelist
