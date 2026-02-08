import SwiftUI
import SwiftData

struct CompletedTasksView: View {
    var body: some View {
        FilteredTaskListView(
            title: "Completed",
            predicate: #Predicate<TaskItem> { $0.isCompleted == true },
            emptyStateType: .noCompleted
        ) { task in
            NavigationLink(value: task) {
                TaskRowView(task: task, statusStyle: .completedMetadata)
            }
            .buttonStyle(.plain)
        }
    }
}