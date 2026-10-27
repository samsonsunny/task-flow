import SwiftUI
import SwiftData

struct TodayTaskList: View {
    let tasks: [TaskItem]
    let onToggleCompletion: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    let onTap: (TaskItem) -> Void
    let onRefresh: () -> Void

    var body: some View {
        List {
            ForEach(tasks) { task in
                let calendar = Calendar.current
                let now = Date()
                let todayStart = calendar.startOfDay(for: now)
                let isOverdueTask: Bool = {
                    guard let dueDate = task.dueDate, !(task.isCompleted ?? false) else { return false }
                    if task.hasTime == true {
                        return dueDate < now
                    } else {
                        return calendar.startOfDay(for: dueDate) < todayStart
                    }
                }()
                TaskRowView(
                    task: task,
                    isCompletedVisualState: task.isCompleted ?? false,
                    onToggleCompletion: { onToggleCompletion(task) },
                    onDelete: { onDelete(task) },
                    onTap: { onTap(task) },
                    showsDueDate: isOverdueTask,
                    showsListName: true,
                    showsGroupName: false,
                    groupNameOverride: nil
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
            }
        }
        .listStyle(.plain)
        .contentMargins(.bottom, 88, for: .scrollContent)
        .refreshable { onRefresh() }
    }
}
