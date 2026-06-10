import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.createdAt) private var allLists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    let onSelect: (ReminderList.ID) -> Void

    private var sortedLists: [ReminderList] {
        let defaultName = ReminderDefaults.defaultListName
        return allLists.sorted { lhs, rhs in
            if lhs.name == defaultName { return true }
            if rhs.name == defaultName { return false }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }
    }

    @State private var isCreatingList = false
    @State private var newListName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sortedLists) { list in
                        listRow(list: list)
                    }

                    if isCreatingList {
                        newListRow
                    }

                    Button {
                        isCreatingList = true
                        newListName = ""
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.colors.primaryAction)
                                .frame(width: 24)

                            Text("New List")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.colors.primaryAction)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .disabled(isCreatingList)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppTheme.colors.surface)
    }

    private var header: some View {
        HStack {
            Text("Lists")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.colors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private func listRow(list: ReminderList) -> some View {
        let count = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID && $0.isCompleted != true }.count

        return Button {
            onSelect(list.persistentModelID)
        } label: {
            HStack(spacing: 12) {
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var newListRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 24)

            TextField("List Name", text: $newListName)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.colors.textPrimary)
                .onSubmit(commitNewList)

            Button {
                commitNewList()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.primaryAction)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func commitNewList() {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            isCreatingList = false
            return
        }
        let list = ReminderList(name: name)
        modelContext.insert(list)
        isCreatingList = false
        newListName = ""
    }
}
