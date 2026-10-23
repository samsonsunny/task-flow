import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext

    /// When set, the view shows only that project's lists. `nil` shows every project.
    var groupID: ReminderListGroup.ID? = nil

    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var viewModel: ListsTabViewModel?
    @State private var creatingArea: ReminderListGroup?
    @State private var renamingList: ReminderList?
    @State private var renameText = ""
    @State private var isRenaming = false
    @State private var deletingList: ReminderList?

    var body: some View {
        listWithDialogs
    }

    private var listWithDialogs: some View {
        listWithRenameAlert
            .overlay {
                if deletingList != nil {
                    ConfirmationOverlay(
                        title: deleteTitle,
                        message: deleteMessage,
                        confirmTitle: "Delete",
                        onConfirm: { commitDelete() },
                        onCancel: { deletingList = nil }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.18), value: deletingList != nil)
    }

    private var listWithRenameAlert: some View {
        listWithCreateSheet
            .alert("Rename List", isPresented: $isRenaming) {
                TextField("List Name", text: $renameText)
                Button("Rename") { commitRename() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose a new name for this list.")
            }
    }

    private var listWithCreateSheet: some View {
        baseList
            .sheet(item: $creatingArea) { area in
                creationSheet(for: area)
            }
    }

    private var baseList: some View {
        content
            .listStyle(.insetGrouped)
            .navigationTitle(navigationTitle)
            .toolbar { EditButton() }
            .onAppear(perform: bootstrap)
            .onChange(of: groups) { _, _ in refresh() }
            .onChange(of: lists) { _, _ in refresh() }
            .onChange(of: allTasks) { _, _ in refresh() }
            .refreshOnModelContextSave(refresh)
    }

    private var content: some View {
        List {
            ForEach(displayedGroups) { group in
                areaSection(group)
            }
        }
    }

    private var displayedGroups: [ReminderListGroup] {
        let domains = groups.filter { $0.isLocked }
        guard let groupID else { return domains }
        return domains.filter { $0.persistentModelID == groupID }
    }

    private var navigationTitle: String {
        guard let groupID,
              let group = groups.first(where: { $0.persistentModelID == groupID })
        else { return "Lists" }
        return areaDisplayName(group.name)
    }

    private func areaSection(_ group: ReminderListGroup) -> some View {
        Section {
            bucketRow(for: group)
            customListRows(for: group)
            newListButton(for: group)
        } header: {
            Text(areaDisplayName(group.name))
        }
    }

    @ViewBuilder
    private func bucketRow(for group: ReminderListGroup) -> some View {
        if let bucket = viewModel?.orderedLists(in: group).first(where: { $0.isBucket }) {
            NavigationLink {
                ListDetailView(listID: bucket.persistentModelID)
            } label: {
                listLabel(bucket)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !group.isLocked {
                    if deletionTarget(for: bucket) != nil {
                        Button {
                            deletingList = bucket
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(AppTheme.colors.error)
                    }

                    Button {
                        presentRename(bucket)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(AppTheme.colors.tint)
                }
            }
        }
    }

    @ViewBuilder
    private func customListRows(for group: ReminderListGroup) -> some View {
        let customLists = (viewModel?.orderedLists(in: group) ?? []).filter { !$0.isBucket }

        ForEach(customLists) { list in
            NavigationLink {
                ListDetailView(listID: list.persistentModelID)
            } label: {
                listLabel(list)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    deletingList = list
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(AppTheme.colors.error)

                Button {
                    presentRename(list)
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                .tint(AppTheme.colors.tint)
            }
        }
        .onMove { fromOffsets, toOffset in
            viewModel?.moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: customLists)
            refresh()
        }
    }

    private func newListButton(for group: ReminderListGroup) -> some View {
        Button {
            Haptics.impact(.light)
            creatingArea = group
        } label: {
            Label("New List", systemImage: "plus")
        }
    }

    private func listLabel(_ list: ReminderList) -> some View {
        HStack(spacing: 12) {
            Image(systemName: list.isBucket ? "tray" : "list.bullet")
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)

                Text(taskCountLabel(for: list))
                    .font(.caption)
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }
        }
    }

    private func taskCountLabel(for list: ReminderList) -> String {
        let count = list.remindersArray.count
        return count == 1 ? "1 task" : "\(count) tasks"
    }

    private var deleteTitle: String {
        guard let deletingList else { return "Delete list?" }
        return "Delete \(deletingList.name)?"
    }

    private var deleteMessage: String {
        guard let deletingList, let destination = deletionTarget(for: deletingList) else {
            return "Its tasks will be moved."
        }
        return "Its tasks will move to \(destination.name)."
    }

    /// A custom list moves its tasks to the area's bucket. A project's bucket moves them to
    /// the oldest remaining list — the same list that inherits the bucket role afterwards.
    private func deletionTarget(for list: ReminderList) -> ReminderList? {
        guard let group = list.group else { return nil }
        guard list.isBucket else { return group.inboxBucket }
        return group.listsArray
            .filter { $0.persistentModelID != list.persistentModelID }
            .min { ($0.createdAt, $0.name) < ($1.createdAt, $1.name) }
    }

    private func creationSheet(for area: ReminderListGroup) -> some View {
        ListCreationSheet(areaName: areaDisplayName(area.name)) { name in
            viewModel?.createList(name: name, in: area)
            refresh()
        }
    }

    private func presentRename(_ list: ReminderList) {
        renamingList = list
        renameText = list.name
        isRenaming = true
    }

    private func commitRename() {
        guard let renamingList else { return }
        viewModel?.renameList(renamingList, to: renameText)
        refresh()
    }

    private func commitDelete() {
        guard let deletingList,
              let target = deletionTarget(for: deletingList)
        else { return }
        viewModel?.deleteList(deletingList, moveTasksTo: target)
        refresh()
    }

    private func bootstrap() {
        if viewModel == nil {
            viewModel = ListsTabViewModel(modelContext: modelContext)
        }
        refresh()
    }

    private func refresh() {
        viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
    }
}

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedBothAreasFixture(into: container)
    return NavigationStack {
        ListsView()
    }
    .modelContainer(container)
    .environment(AppState())
}
