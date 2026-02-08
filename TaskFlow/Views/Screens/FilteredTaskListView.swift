import SwiftUI
import SwiftData

struct FilteredTaskListView<RowContent: View>: View {
    @Environment(\.modelContext) private var modelContext

    let title: String
    let predicate: Predicate<TaskItem>
    let emptyStateType: EmptyStateView.EmptyStateType
    let rowContent: (TaskItem) -> RowContent

    @Query var tasks: [TaskItem]

    init(title: String, predicate: Predicate<TaskItem>, emptyStateType: EmptyStateView.EmptyStateType, @ViewBuilder rowContent: @escaping (TaskItem) -> RowContent) {
        self.title = title
        self.predicate = predicate
        self.emptyStateType = emptyStateType
        self.rowContent = rowContent
        self._tasks = Query(filter: predicate, sort: \TaskItem.dueDate)
    }

    var body: some View {
        ZStack {
            AppTheme.colors.background
                .ignoresSafeArea()

            if tasks.isEmpty {
                EmptyStateView(type: emptyStateType)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing.md) { // Use consistent spacing for list items
                        ForEach(tasks) { task in
                            rowContent(task) // Render row using the provided closure
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing.lg) // Use consistent horizontal padding
                    .padding(.top, AppTheme.spacing.md) // Use consistent top padding
                    .padding(.bottom, AppTheme.spacing.lg) // Use consistent bottom padding
                }
            }
        }
        .navigationTitle(title)
    }
}
