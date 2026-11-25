import SwiftUI
import SwiftData

struct TodayTaskList: View {
    let tasks: [TaskItem]
    let actions: TaskRowActions
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
                    actions: actions,
                    showsDueDate: isOverdueTask,
                    showsListName: true,
                    enablesFallbackSwipe: true
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(
                    top: AppSpacing.xs,
                    leading: AppSpacing.screenHorizontal,
                    bottom: AppSpacing.xs,
                    trailing: AppSpacing.screenHorizontal
                ))
            }
        }
        .listStyle(.plain)
        .contentMargins(.bottom, 88, for: .scrollContent)
        .refreshable { onRefresh() }
    }
}
