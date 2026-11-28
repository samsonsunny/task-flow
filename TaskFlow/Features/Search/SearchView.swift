import SwiftData
import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted != true }, sort: \TaskItem.createdAt, order: .reverse)
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.safeTitle)
                            Text(task.reminderList?.group?.name ?? "No Domain")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search Tasks")
        }
    }
}
