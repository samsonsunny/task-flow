## 1. Shared Selection Infrastructure

- [x] 1.1 Create `BulkActionsToolbar` view component with Date, Move, Tag, Complete, Delete buttons, selection count, and Done button
- [x] 1.2 Create selection circle component/modifier for TaskRowView that replaces completion circle in selection mode
- [x] 1.3 Add `isSelecting` and `selectedTasks` @State to ReminderSegmentDetailView with enter/exit selection mode logic (save/restore collapsedTasks)
- [x] 1.4 Wire ⋯ button to Menu with "Select Items" as first item in TodayView, TomorrowView, UpcomingView

## 2. TaskRowView Selection Mode

- [x] 2.1 Add `isSelecting` and `isSelected` parameters to TaskRowView
- [x] 2.2 Implement selection circle that replaces completion circle when `isSelecting` is true
- [x] 2.3 Change tap gesture to toggle selection when `isSelecting` is true (instead of opening editor)
- [x] 2.4 Add row tint (subtle blue background) when `isSelected` is true
- [x] 2.5 Disable context menu when `isSelecting` is true
- [x] 2.6 Animate selection circle entrance/exit

## 3. TimelineView Selection Support

- [x] 3.1 Pass selection state through to taskListRow in ReminderSegmentDetailView
- [x] 3.2 Disable swipe actions when `isSelecting` is true
- [x] 3.3 Hide FAB when `isSelecting` is true
- [x] 3.4 Hide quick capture row when `isSelecting` is true
- [x] 3.5 Add BulkActionsToolbar overlay that appears when `isSelecting` is true
- [x] 3.6 Replace ⋯ with "Done" button when `isSelecting` is true (in TodayView, TomorrowView, UpcomingView toolbar)

## 4. ListDetailView Selection Support

- [x] 4.1 Add ⋯ toolbar menu to ListDetailView with "Select Items" option
- [x] 4.2 Add `isSelecting` and `selectedTasks` @State to ListDetailView
- [x] 4.3 Pass selection state to taskListRow
- [x] 4.4 Disable swipe actions and drag-drop when `isSelecting` is true
- [x] 4.5 Hide FAB when `isSelecting` is true
- [x] 4.6 Add BulkActionsToolbar overlay
- [x] 4.7 Replace ⋯ with "Done" button when `isSelecting` is true

## 5. CompletedView Selection Support

- [x] 5.1 Add ⋯ toolbar menu to CompletedView with "Select Items" option
- [x] 5.2 Add `isSelecting` and `selectedTasks` @State to CompletedView
- [x] 5.3 Add selection circle to completed task row (replaces uncomplete button in selection mode)
- [x] 5.4 Disable swipe actions when `isSelecting` is true
- [x] 5.5 Add BulkActionsToolbar overlay
- [x] 5.6 Replace ⋯ with "Done" button when `isSelecting` is true

## 6. ViewModel Bulk Operations

- [x] 6.1 Add bulk reschedule methods to ReminderSegmentViewModel (rescheduleSelectedToToday/Tomorrow/NextWeek/Later)
- [x] 6.2 Add bulk move method to ReminderSegmentViewModel (moveSelectedToList)
- [x] 6.3 Add bulk complete/incomplete method to ReminderSegmentViewModel (toggleCompletionForSelected)
- [x] 6.4 Add bulk delete method to ReminderSegmentViewModel (deleteSelected) with haptic + notification cleanup
- [x] 6.5 Add bulk priority method to ReminderSegmentViewModel (setPriorityForSelected)
- [x] 6.6 Add equivalent bulk methods to ListDetailViewModel
- [x] 6.7 Add bulk uncomplete and delete methods to CompletedViewModel

## 7. Integration & Polish

- [x] 7.1 Add confirmation alert for bulk delete (shows count, destructive styling)
- [x] 7.2 Wire BulkActionsToolbar buttons to ViewModel bulk methods in ReminderSegmentDetailView
- [x] 7.3 Wire BulkActionsToolbar buttons to ViewModel bulk methods in ListDetailView
- [x] 7.4 Wire BulkActionsToolbar buttons to ViewModel bulk methods in CompletedView
- [x] 7.5 Test selection mode across all 6 screens
- [x] 7.6 Test subtask auto-expand/restore behavior
- [x] 7.7 Test edge cases: empty list, single task, all tasks selected
