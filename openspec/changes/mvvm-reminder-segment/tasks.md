## 1. Create ReminderSegmentViewModel

- [ ] 1.1 Create `TaskFlow/Features/Reminders/ViewModels/ReminderSegmentViewModel.swift` with `@Observable` class
- [ ] 1.2 Add `modelContext`, `segment` properties and `init(modelContext:segment:overdueTasks:)`
- [ ] 1.3 Add `now` stored property with `refreshNow()` method for timer updates
- [ ] 1.4 Add `showOverdue` toggle, `overdueTasks` array
- [ ] 1.5 Add `justCompleted` set for animation tracking
- [ ] 1.6 Add `update(tasks:lists:now:)` entry point computing all derived state

## 2. Move Derived State Computation to ViewModel

- [ ] 2.1 Add `filteredTasks`, `groupedSections`, `upcomingGroups`, `sortedFlatTasks` calling `ReminderSegmentLogic` and `TaskUIModel`
- [ ] 2.2 Add `contextualDate`, `captureDateHint` for segment-aware date logic
- [ ] 2.3 Add `resolvedQuickCaptureList()`, `shouldShowDueDate()` helpers
- [ ] 2.4 Add `otherLists` computed property (all lists minus current)

## 3. Move Data Mutations to ViewModel

- [ ] 3.1 Add `toggleCompletion(for:)` with haptic, justCompleted, notification cancellation
- [ ] 3.2 Add `commitQuickCapture(text:captureDate:)` creating `TaskItem` with segment dates
- [ ] 3.3 Add `openQuickCaptureEditor(text:captureDate:)` returning config values
- [ ] 3.4 Add `delete(task:)` with notification cancellation
- [ ] 3.5 Add `moveTask(_:to:)` and `assignSortOrder(for:in:)`
- [ ] 3.6 Add `scheduleTask(_:dueDate:hasTime:)` for schedule sheet commits
- [ ] 3.7 Add `rescheduleToToday(_:)`, `rescheduleToTomorrow(_:)`, `rescheduleToLater(_:)`
- [ ] 3.8 Add `canMoveToToday(_:)`, `canMoveToTomorrow(_:)`

## 4. Refactor ReminderSegmentDetailView to use ViewModel

- [ ] 4.1 Add `@State private var viewModel: ReminderSegmentViewModel` initialized from environment
- [ ] 4.2 Replace all computed properties with `viewModel.` references
- [ ] 4.3 Replace all private mutation methods with `viewModel.` calls
- [ ] 4.4 Add `.onReceive(refreshTimer)` calling `viewModel.refreshNow()`
- [ ] 4.5 Wire `.onChange` and `.onAppear` to call `viewModel.update(...)`
- [ ] 4.6 Remove all `@Environment(\.modelContext)` usage from view
- [ ] 4.7 Remove all direct `modelContext` mutations from the view

## 5. Update TodayTabView if needed

- [ ] 5.1 Pass `modelContext` or adjust initialization for ViewModel injection

## 6. Verify

- [ ] 6.1 Build succeeds with no warnings
- [ ] 6.2 Today segment shows overdue + today tasks correctly
- [ ] 6.3 Tomorrow segment shows tomorrow tasks
- [ ] 6.4 Upcoming segment shows grouped month/day sections
- [ ] 6.5 Later and Overdue segments work correctly
- [ ] 6.6 Task completion toggling works across all segments
- [ ] 6.7 Quick capture assigns correct contextual dates
- [ ] 6.8 Schedule sheet opens and commits correctly
- [ ] 6.9 Reschedule (Today, Tomorrow, Later) works
- [ ] 6.10 Timer refresh updates overdue count after midnight
