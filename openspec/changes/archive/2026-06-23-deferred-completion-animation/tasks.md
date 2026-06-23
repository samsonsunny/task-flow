## 1. ReminderSegmentDetailView

- [x] 1.1 Add `@State private var justCompleted: Set<String> = []`
- [x] 1.2 Modify `sortedFlatTasks` / visible tasks to include recently completed tasks from `justCompleted` set
- [x] 1.3 Add `.transition(.scale.combined(with: .opacity))` to each task row
- [x] 1.4 In `toggleCompletion`, add task ID to `justCompleted` and schedule removal via `DispatchQueue.main.asyncAfter(deadline: .now() + 0.6)`
- [x] 1.5 Wire `withAnimation` around the removal from `justCompleted` set
- [x] 2.1 Same changes as section 1, applied to `ListDetailView`
