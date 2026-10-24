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
                TaskRowView(
                    task: task,
                    isCompletedVisualState: task.isCompleted ?? false,
                    onToggleCompletion: { onToggleCompletion(task) },
                    onDelete: { onDelete(task) },
                    onTap: { onTap(task) },
                    showsDueDate: true,
                    showsListName: true,
                    showsGroupName: false,
                    groupNameOverride: nil
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .contentMargins(.bottom, 88, for: .scrollContent)
        .refreshable { onRefresh() }
    }
}
