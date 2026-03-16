import SwiftUI

struct TaskListUpcomingView: View {
    let tasks: [TaskItem]
    let row: (TaskItem) -> AnyView

    var body: some View {
        if tasks.isEmpty {
            emptyStateRow
        } else {
            ForEach(tasks) { task in
                row(task)
            }
        }
    }

    private var emptyStateRow: some View {
        VStack(alignment: .leading) {
            Text("Nothing in Upcoming")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Future tasks will appear here when you schedule them.")
                .font(AppTheme.fonts.body)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
    }

    // Section headers removed for MVP simplicity.
}
