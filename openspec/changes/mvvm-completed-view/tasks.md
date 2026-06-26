## 1. Create CompletedViewModel

- [ ] 1.1 Create `TaskFlow/Features/Reminders/ViewModels/CompletedViewModel.swift` with `@Observable` class
- [ ] 1.2 Add `modelContext` property and `init(modelContext:)`
- [ ] 1.3 Add `recentCompletedTasks`, `groupedTasks` with `update(tasks:)` entry point
- [ ] 1.4 Add static `computeRecentTasks(_:)` for 30-day filtering
- [ ] 1.5 Add static `computeGroupedTasks(_:)` for Today/Yesterday/This Week/Earlier grouping
- [ ] 1.6 Add `uncomplete(_:)` with notification rescheduling
- [ ] 1.7 Add `delete(_:)` with notification cancellation
- [ ] 1.8 Add `destinationLabel(for:)` helper

## 2. Refactor CompletedView to use ViewModel

- [ ] 2.1 Create VM from environment `modelContext`
- [ ] 2.2 Replace all computed properties with `viewModel.` references
- [ ] 2.3 Replace `uncomplete(_:)` and delete closures with VM calls
- [ ] 2.4 Remove all `@Environment(\.modelContext)` usage and direct mutations

## 3. Verify

- [ ] 3.1 Build succeeds with no warnings
- [ ] 3.2 Completed tasks appear grouped correctly
- [ ] 3.3 Un-complete restores task and schedules notification
- [ ] 3.4 Swipe-to-delete removes task and cancels notification
- [ ] 3.5 Destination label shows correct text for each date scenario
