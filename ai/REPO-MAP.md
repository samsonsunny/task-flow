# Repository Map

60 Swift files / ~10.2k lines. Line counts are approximate and change over time; use them to decide whether to open a file or grep within it.

## Root

| Path | Role |
|---|---|
| `AGENTS.md` | Tier-0 agent entry point; binding invariants |
| `ai/` | This navigation system |
| `README.md` | Product overview, release/versioning process |
| `TaskFlow.xcodeproj/` | Xcode project; `PBXFileSystemSynchronizedRootGroup` auto-discovers sources |
| `TaskFlow/` | All app source |
| `scripts/publish-devto.mjs` | Forem API publisher (230 lines) |
| `scripts/email_agent.py` | Microsoft Graph read + SMTP send daemon with Outlook OAuth2; runs approved email requests via `opencode run` directly in the clean `main` checkout and pushes to origin |
| `scripts/email-agent` | Wrapper that creates `.email-agent/venv`, installs `msal`, and launches the daemon |
| `scripts/requirements-email-agent.txt` | Python dependency for the email daemon |
| `scripts/com.taskflow.email-agent.plist` | launchd agent for 60-second polling |
| `.opencode/agents/email-dev.md` | Restricted opencode agent used by the email daemon |
| `ci_scripts/` | Xcode Cloud version/tag script + release notes |
| `.github/workflows/devto-publish.yml` | PR → Dev.to draft; merge → live publish |
| `articles/` | Published article sources and Dev.to distribution log |
| `package.json` | Dev dependencies only (`app-store-scraper`, `playwright`); no scripts |

Never load: `.derivedData/`, `DerivedData/`, `build/`, `.env`, `.email-agent/`, `.DS_Store`. Xcode user-data and Ralph state were removed; do not re-add them.

## Source tree

### Live surfaces

| Directory | Files / lines | Entry point |
|---|---|---|
| `App/` | 3 / 270 | `TaskFlowApp.swift`, `ContentView.swift`, `AppState.swift` |
| `Features/` root | 1 / 157 | `MainTabView.swift` — four fixed tabs |
| `Features/Today/` | 10 / 1,648 | `TodayTaskListView.swift`, `TodayViewModel.swift` |
| `Features/Areas/` | 3 / 722 | `AreaTasksView.swift`, `AreaTasksViewModel.swift`, `AreaBoardView.swift` |
| `Features/Lists/` | 5 / 1,368 | `ListView.swift`, `ListViewModel.swift`, `DetailView.swift`, `DetailViewModel.swift` |
| `Features/Editor/` | 6 / 1,221 | `EditorView.swift`, `EditorViewModel.swift`, `Draft.swift` |
| `Features/Settings/` | 1 / 154 | `MoreView.swift` |
| `Views/Components/` | 8 / 789 | `TaskRowView.swift`, `BulkActionsToolbar.swift` |
| `Models/` | 4 / 1,631 | `TaskItem.swift`, `AreaReconciler.swift` |
| `DesignSystem/` | 4 / 179 | `Colors.swift`, `Typography.swift`, `Theme.swift`, `Radius.swift` |
| `Utilities/` | 11 / 582 | `NotificationService.swift`, `SortOrderMidpoint.swift`, etc. |
| `Previews/` | 1 / 304 | `TaskPreviewData.swift` |

### Live helpers in a legacy-named folder

`Features/Tasks/Timeline/` keeps three files with no surviving UI. Do not delete them: active code depends on their date/ordering helpers. Do not add new screens here.

| Directory | Files / lines | Note |
|---|---|---|
| `Features/Tasks/Timeline/` | 3 / 1,157 | `ReminderSegment`, `ReminderSegmentLogic`, `TaskUIModel`, `ReminderSegmentViewModel` helpers |

Deleted as dead code: `Features/Home/`, `TimelineView.swift`, and the `Today`/`Tomorrow`/`Upcoming` stub views.

## File-level index

### App + Models + Previews

| File | Lines | Declares / role |
|---|---:|---|
| `App/TaskFlowApp.swift` | 124 | `TaskFlowApp` — container, schema, CloudKit config |
| `App/ContentView.swift` | 48 | `ContentView` — root host |
| `App/AppState.swift` | 98 | `AppState` — app-level state |
| `Models/TaskItem.swift` | 1,180 | `TaskItem`, `ReminderList`, `ReminderTag`, schema versions V1–V3 |
| `Models/AreaReconciler.swift` | 337 | `AreaNames`, `LockedAreaState` — seeds/locks Work + Personal |
| `Models/SortOrderBackfill.swift` | 80 | Sort order migration helper |
| `Models/ListSection.swift` | 35 | `ListSection` |
| `Previews/TaskPreviewData.swift` | 304 | `TaskPreviewData` — preview container/seeds |

### Features/Today (cross-domain)

| File | Lines | Declares / role |
|---|---:|---|
| `Today/UpcomingAgendaView.swift` | 324 | `UpcomingAgendaView`, `UpcomingDaySection` |
| `Today/MonthCalendarView.swift` | 306 | `MonthCalendarView` — multi-year strip |
| `Today/TodayViewModel.swift` | 256 | `TodayViewModel`, `TodayAreaFilter`, `TodaySection` |
| `Today/ScheduledTaskListView.swift` | 212 | `ScheduledTaskListView`, `ScheduledDaySection` |
| `Today/TodayTaskListView.swift` | 192 | `TodayTaskListView` — tab surface |
| `Today/ScheduledTasksView.swift` | 177 | `ScheduledTasksView` |
| `Today/TodayNavigationStackView.swift` | 59 | `TodayNavigationStackView`, `TodayRoute` |
| `Today/TaskListContentHeader.swift` | 45 | `TaskListContentHeader` |
| `Today/TodayTaskList.swift` | 45 | `TodayTaskList` |
| `Today/TodayDateWindow.swift` | 32 | `TodayDateWindow` — date bounds |

### Features/Areas, Lists, Editor, Settings

| File | Lines | Declares / role |
|---|---:|---|
| `Areas/AreaBoardView.swift` | 273 | `AreaBoardView`, `BoardColumnView`, `BoardTaskCard` |
| `Areas/AreaTasksView.swift` | 262 | `AreaTasksView`, `AreaDisplayMode` |
| `Areas/AreaTasksViewModel.swift` | 187 | `AreaTasksViewModel` |
| `Lists/DetailViewModel.swift` | 486 | `ListDetailViewModel` |
| `Lists/DetailView.swift` | 409 | `ListDetailView`, schedule configs |
| `Lists/ListView.swift` | 263 | `ListsView` |
| `Lists/ListViewModel.swift` | 161 | `ListsTabViewModel` |
| `Lists/ListCreationSheet.swift` | 49 | `ListCreationSheet` |
| `Editor/EditorView.swift` | 477 | `ReminderEditorView`, `SubtaskScheduleConfig` |
| `Editor/EditorViewModel.swift` | 252 | `ReminderEditorViewModel` |
| `Editor/Draft.swift` | 192 | `ReminderDraft`, `ReminderDraftMapper` |
| `Editor/DatePickerSheet.swift` | 135 | `TaskScheduleDatePickerSheet` |
| `Editor/ListPickerView.swift` | 110 | `ListPickerView` |
| `Editor/DatePickerViewModel.swift` | 55 | `TaskScheduleDatePickerViewModel`, `ExpandedPicker` |
| `Settings/MoreView.swift` | 154 | `MoreView` — completed archive, settings |

### Shared UI + utilities

| File | Lines | Declares / role |
|---|---:|---|
| `Views/Components/TaskRowView.swift` | 457 | `TaskRowView`, `DueDateAction` |
| `Views/Components/BulkActionsToolbar.swift` | 114 | `BulkActionsToolbar` |
| `Views/Components/ConfirmationOverlay.swift` | 72 | `ConfirmationOverlay` |
| `Views/Components/UndoToast.swift` | 59 | `UndoToast` |
| `Views/Components/FloatingAddButton.swift` | 34 | `FloatingAddButton` |
| `Views/Components/SelectionCircle.swift` | 26 | `SelectionCircle` |
| `Views/Components/NonDismissingTextField.swift` | 17 | `NonDismissingTextField` |
| `Views/Components/SyncRefresh.swift` | 11 | Sync refresh view modifier |
| `Utilities/NotificationService.swift` | 153 | `NotificationService`, `DailyReminderKeys` |
| `Utilities/SortOrderMidpoint.swift` | 96 | Ordering math |
| `Utilities/TabBarVisibilityAdjuster.swift` | 75 | `TabBarVisibilityAdjuster` |
| `Utilities/ScrollAnimationController.swift` | 72 | `ScrollAnimationController` |
| `Utilities/TaskTreeFlattener.swift` | 71 | `TaskTreeFlattener`, `FlatTaskNode` |
| `Utilities/InteractivePopGestureEnabler.swift` | 42 | `InteractivePopGestureEnabler` |
| `Utilities/BadgeService.swift` | 19 | `BadgeService` |
| `Utilities/PersistentIdentifier+StableKey.swift` | 19 | Stable key helper |
| `Utilities/Haptics.swift` | 16 | `Haptics` |
| `Utilities/DateRounding.swift` | 10 | Date rounding |
| `Utilities/CompletionUndo.swift` | 9 | `CompletionUndo` |
| `DesignSystem/Colors.swift` | 58 | `AppColors` — semantic tokens |
| `DesignSystem/Typography.swift` | 65 | `AppFont` |
| `DesignSystem/Theme.swift` | 42 | `AppTheme`, `AppAppearance` |
| `DesignSystem/Radius.swift` | 14 | `AppRadius` |

### Shared helpers under `Features/Tasks/Timeline/`

| File | Lines | Declares / role |
|---|---:|---|
| `Tasks/Timeline/TimelineViewModel.swift` | 601 | `ReminderSegmentViewModel` — `nextSaturday`/`nextMonday` used by `EditorViewModel`, `DetailViewModel`, `TaskRowView` |
| `Tasks/Timeline/TimeSegments.swift` | 308 | `ReminderSegment`, `ReminderSegmentLogic` — `badgeCount` used by `BadgeService` |
| `Tasks/Timeline/TimelineSections.swift` | 248 | `TaskUIModel`, `UpcomingGroup`, `DatedSection` |
