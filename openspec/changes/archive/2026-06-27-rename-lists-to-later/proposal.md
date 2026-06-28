## Why

The 4th tab is called "Lists" but its role is broader: it is the permanent organizational home for all tasks, groups, and lists. Renaming it to "Later" aligns the tab's label with its purpose and joins the time-continuum naming of the other tabs (Today → Tomorrow → Upcoming → Later). The default catch-all list "Reminders" is renamed to "Inbox" to signal it as a staging area. The unused `ReminderSegment.later` enum case is removed.

## What Changes

- **BREAKING**: Tab label `Lists` → `Later` in `MainTabView`
- **BREAKING**: Default list name `"Reminders"` → `"Inbox"` (constant in `TaskItem.swift` + one-time migration for existing stores)
- **BREAKING**: Remove `ReminderSegment.later` case from enum and filter logic in `TimeSegments.swift`
- **UPDATE**: `tab-bar-navigation` spec — remove the requirement that "Later and Completed have no entry point"; add Later tab definition
- Archive stale `sidebar-navigation` spec (sidebar was removed in a previous refactor)
- Update file organization comment in `AGENTS.md`

## Capabilities

### New Capabilities

- `app-mental-model`: The two-axis product model (attention vs home) previously documented in `openspec/specs/app-mental-model/spec.md`. This change implements the first phase: tab rename, Inbox rename, dead code removal.

### Modified Capabilities

- `tab-bar-navigation`: The 4th tab is renamed from "Lists" to "Later". The requirement that "Later and Completed have no entry point" is replaced with a Later tab definition (permanent organizational home showing groups and lists). The default list is named "Inbox".

## Impact

- `TaskFlow/Features/MainTabView.swift` — tab item label and icon
- `TaskFlow/Models/TaskItem.swift` — `ReminderDefaults.defaultListName` constant
- `TaskFlow/Features/Tasks/Timeline/TimeSegments.swift` — remove `.later` case and filter branch
- `TaskFlow/App/ContentView.swift` — add one-time migration to rename existing "Reminders" list to "Inbox"
- `TaskFlow/Features/Lists/ListView.swift` — navigation title "All Lists" (cosmetic, optional)
- `openspec/specs/tab-bar-navigation/spec.md` — remove "Later has no entry point" requirement, add Later tab requirement
- `openspec/specs/app-mental-model/spec.md` — already created during discovery
- `openspec/specs/sidebar-navigation/spec.md` — archive (stale)
