import SwiftUI
import SwiftData

struct ListsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.createdAt) private var allLists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var isCreatingList = false
    @State private var newListName = ""

    private var sortedLists: [ReminderList] {
        let defaultName = ReminderDefaults.defaultListName
        return allLists.sorted { lhs, rhs in
            if lhs.name == defaultName { return true }
            if rhs.name == defaultName { return false }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedLists) { list in
                    NavigationLink {
                        ListDetailView(listID: list.persistentModelID)
                    } label: {
                        listRow(list: list)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.colors.appBackground)
            .navigationTitle("All Lists")
            .toolbar {
                ToolbarItem {
                    Button {
                        newListName = ""
                        isCreatingList = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New List", isPresented: $isCreatingList) {
                TextField("List Name", text: $newListName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let list = ReminderList(name: name)
                    modelContext.insert(list)
                }
            }
        }
    }

    private func listRow(list: ReminderList) -> some View {
        let count = allTasks.filter {
            $0.reminderList?.persistentModelID == list.persistentModelID && $0.isCompleted != true
        }.count

        return HStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 24)

            Text(list.name)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.colors.textPrimary)

            Spacer()

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.colors.fillSubtle)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
