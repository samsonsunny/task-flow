import SwiftData
import SwiftUI

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var actions = TaskActionsViewModel()

    @Query(
        filter: #Predicate<TaskItem> { $0.isCompleted != true },
        sort: \TaskItem.createdAt,
        order: .reverse
    )
    private var tasks: [TaskItem]

    private var results: [TaskItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return tasks.filter { task in
            task.safeTitle.localizedCaseInsensitiveContains(needle)
                || task.safeDescription.localizedCaseInsensitiveContains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView.search
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(results) { task in
                        TaskRowView(task: task, showsDomain: true)
                            .taskActions(
                                task: task,
                                onToggle: { actions.toggleCompletion(for: task, in: modelContext) },
                                onDelete: { actions.delete(task, in: modelContext) }
                            )
                            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                            .listRowBackground(Color(uiColor: .systemBackground))
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search Tasks")
            .animation(.easeOut(duration: 0.2), value: actions.revision)
        }
    }
}
