## 1. Create ListDetailViewModel

- [ ] 1.1 Create `TaskFlow/Features/Reminders/ViewModels/ListDetailViewModel.swift` with `@Observable` class
- [ ] 1.2 Add `listID`, `modelContext` properties and `init(modelContext:listID:)`
- [ ] 1.3 Add `allTasks`, `allLists`, `now` stored properties with `update(tasks:lists:allTasks:now:)` entry point
- [ ] 1.4 Add `list`, `tasks`, `rootTasks` computed properties matching current view logic
- [ ] 1.5 Add `flatNodes`, `flattenTasks()`, `flattenNode()` with collapse support, `flatToTaskIndex()`
- [ ] 1.6 Add `collapsedTasks` set with `toggleCollapse(_:)`
- [ ] 1.7 Add `justCompleted` set with `toggleCompletion(for:)` including animation delay

## 2. Move Data Mutations to ViewModel

- [ ] 2.1 Add `commitQuickCapture(text:in:)` creating `TaskItem` with list assignment
- [ ] 2.2 Add `delete(task:)` with notification cancellation
- [ ] 2.3 Add `moveTask(_:to:)` and `assignSortOrder(for:in:)` for list-to-list moves
- [ ] 2.4 Add `moveTasks(fromOffsets:toOffset:)` using midpoint/widen algorithm
- [ ] 2.5 Add `handleDrop(target:location:)`, `moveTaskToRoot()`, `isDescendant(_:of:)` for drag-drop
- [ ] 2.6 Add `presentScheduleSheet(for:)`, `scheduleTask(_:dueDate:hasTime:)`, reschedule helpers
- [ ] 2.7 Add `canMoveToToday(_:)` / `canMoveToTomorrow(_:)` / `otherLists`
- [ ] 2.8 Add `openQuickCaptureEditor(text:listID:)` and `commitQuickCapture(text:in:)`

## 3. Refactor ListDetailView to use ViewModel

- [ ] 3.1 Add `@State private var viewModel: ListDetailViewModel` initialized from environment
- [ ] 3.2 Replace all computed properties with `viewModel.` references
- [ ] 3.3 Replace all private mutation methods with `viewModel.` calls
- [ ] 3.4 Add `.onReceive(refreshTimer)` calling `viewModel.refreshNow()`
- [ ] 3.5 Wire `.onChange` and `.onAppear` to call `viewModel.update(...)`
- [ ] 3.6 Remove all `@Environment(\.modelContext)` usage from view (VM owns it)
- [ ] 3.7 Remove all direct `modelContext` mutations from the view

## 4. Verify

- [ ] 4.1 Build succeeds with no warnings
- [ ] 4.2 Task completion toggling works inline
- [ ] 4.3 Drag-drop reorder within list works
- [ ] 4.4 Drag-drop nesting works (parent-child)
- [ ] 4.5 Quick capture creates task in correct list
- [ ] 4.6 Swipe-to-delete works with notification cancellation
- [ ] 4.7 Schedule sheet opens and commits correctly
- [ ] 4.8 Move to another list works
- [ ] 4.9 Collapse/expand subtasks works
