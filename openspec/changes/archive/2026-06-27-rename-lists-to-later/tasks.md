## 1. Core Renames

- [x] 1.1 Rename tab label from "Lists" to "Later" in `MainTabView.swift` (tab item label and icon)
- [x] 1.2 Rename default list constant `ReminderDefaults.defaultListName` from "Reminders" to "Inbox" in `TaskItem.swift`
- [x] 1.3 Add one-time migration in `ContentView.swift` to find existing "Reminders" list and rename to "Inbox" (skip if "Inbox" already exists)

## 2. Dead Code Removal

- [x] 2.1 Remove `case later` from `ReminderSegment` enum and all associated switch branches (title, icon, tintColor, usesGroupedSections, emptyTitle, emptyMessage)
- [x] 2.2 Remove `case .later:` branch from `ReminderSegmentLogic.filteredTasks` in `TimeSegments.swift`
- [x] 2.3 Remove `case .later:` from `shouldShowDueDate` in `TimelineViewModel.swift`
- [x] 2.4 Verify no remaining references to `ReminderSegment.later` compile

## 3. Spec and Documentation Cleanup

- [x] 3.1 Update `tab-bar-navigation/spec.md` — confirm Later tab definition, default "Inbox" list name, and removed "no entry point" requirement
- [x] 3.2 Archive `sidebar-navigation/spec.md` — mark all requirements as REMOVED

## 4. Verify

- [x] 4.1 Build and run — confirm tab bar shows Today, Tomorrow, Upcoming, Later
- [x] 4.2 Confirm default list is named "Inbox" on fresh install
- [x] 4.3 Confirm existing "Reminders" list is renamed to "Inbox" on migration
- [x] 4.4 Confirm `ReminderSegment.later` references produce compiler errors (none expected)
- [x] 4.5 Run existing test suite

## 5. Design Refinements

- [x] 5.1 Update tab icons to clock progression: Today (`clock.fill`), Tomorrow (`clock.arrow.2.circlepath`), Upcoming (`calendar.badge.clock`), Later (`tray.full`)
- [x] 5.2 Change Later tab navigation title from "All Lists" to "Later"
- [x] 5.3 Give Inbox list a distinctive row icon (`tray`), other lists keep `list.bullet`
