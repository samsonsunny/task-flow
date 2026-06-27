import SwiftUI
import SwiftData

struct ListsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    let onSettings: () -> Void

    @State private var viewModel: ListsTabViewModel?

    var body: some View {
        NavigationStack {
            alertsContainer
        }
    }

    private var listContent: some View {
        List {
            defaultListSection
            ungroupedSection
            groupSections
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.colors.appBackground)
        .navigationTitle("All Lists")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ReminderFloatingAddButton {
                viewModel?.newListName = ""
                viewModel?.isCreatingList = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
    }

    private var alertsContainer: some View {
        listContent
            .alert("New List", isPresented: Binding(
                get: { viewModel?.isCreatingList ?? false },
                set: { viewModel?.isCreatingList = $0 }
            )) {
                TextField("List Name", text: Binding(
                    get: { viewModel?.newListName ?? "" },
                    set: { viewModel?.newListName = $0 }
                ))
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    viewModel?.createList(name: viewModel?.newListName ?? "")
                }
            }
            .alert("New Group", isPresented: Binding(
                get: { viewModel?.isCreatingGroup ?? false },
                set: { viewModel?.isCreatingGroup = $0 }
            )) {
                TextField("Group Name", text: Binding(
                    get: { viewModel?.newGroupName ?? "" },
                    set: { viewModel?.newGroupName = $0 }
                ))
                Button("Cancel", role: .cancel) {
                    viewModel?.groupSourceList = nil
                }
                Button("Create") {
                    viewModel?.createGroup(name: viewModel?.newGroupName ?? "", sourceList: viewModel?.groupSourceList)
                    viewModel?.groupSourceList = nil
                }
            }
            .alert("Rename List", isPresented: Binding(
                get: { viewModel?.isRenamePresented ?? false },
                set: { viewModel?.isRenamePresented = $0 }
            )) {
                TextField("List Name", text: Binding(
                    get: { viewModel?.renameText ?? "" },
                    set: { viewModel?.renameText = $0 }
                ))
                Button("Cancel", role: .cancel) {
                    viewModel?.renameList = nil
                }
                Button("Rename") {
                    if let list = viewModel?.renameList {
                        viewModel?.renameList(list, to: viewModel?.renameText ?? "")
                    }
                    viewModel?.renameList = nil
                }
            }
            .alert("Rename Group", isPresented: Binding(
                get: { viewModel?.isGroupRenamePresented ?? false },
                set: { viewModel?.isGroupRenamePresented = $0 }
            )) {
                TextField("Group Name", text: Binding(
                    get: { viewModel?.groupRenameText ?? "" },
                    set: { viewModel?.groupRenameText = $0 }
                ))
                Button("Cancel", role: .cancel) {
                    viewModel?.renameGroup = nil
                }
                Button("Rename") {
                    if let group = viewModel?.renameGroup {
                        viewModel?.renameGroup(group, to: viewModel?.groupRenameText ?? "")
                    }
                    viewModel?.renameGroup = nil
                }
            }
            .alert("Delete Group", isPresented: Binding(
                get: { viewModel?.deleteGroup != nil },
                set: { if !$0 { viewModel?.deleteGroup = nil } }
            )) {
                Button("Delete Group & Lists", role: .destructive) {
                    if let group = viewModel?.deleteGroup {
                        viewModel?.deleteGroup(group)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let group = viewModel?.deleteGroup {
                    Text("Delete \"\(group.name)\" and all lists inside? This cannot be undone.")
                }
            }
            .alert("Delete List", isPresented: Binding(
                get: { viewModel?.deleteList != nil },
                set: { if !$0 { viewModel?.deleteList = nil } }
            )) {
                Button("Move tasks to Reminders") {
                    if let list = viewModel?.deleteList {
                        viewModel?.deleteList(list, moveTasksToDefault: true)
                    }
                }
                Button("Delete All Tasks", role: .destructive) {
                    if let list = viewModel?.deleteList {
                        viewModel?.deleteList(list, moveTasksToDefault: false)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let list = viewModel?.deleteList {
                    Text("What should happen to the tasks in \"\(list.name)\"?")
                }
            }
            .onAppear {
                viewModel = ListsTabViewModel(modelContext: modelContext)
                viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
            }
            .onChange(of: lists) { _, _ in
                viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
            }
            .onChange(of: groups) { _, _ in
                viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
            }
            .onChange(of: allTasks) { _, _ in
                viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
            }
    }

    // MARK: - Default List Section

    private var defaultListSection: some View {
        Section {
            if let defaultList = viewModel?.defaultList {
                NavigationLink {
                    ListDetailView(listID: defaultList.persistentModelID)
                } label: {
                    listRow(list: defaultList)
                }
            }
        }
    }

    // MARK: - Ungrouped Lists Section

    private var ungroupedSection: some View {
        let items = viewModel?.ungroupedLists ?? []
        return Group {
            if !items.isEmpty {
                Section {
                    ForEach(items) { list in
                        listNavigationLink(for: list)
                    }
                    .onMove { fromOffsets, toOffset in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel?.moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: items)
                        }
                    }
                } header: {
                    HStack {
                        Text("LISTS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.colors.textSecondary)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Group Sections

    private var groupSections: some View {
        ForEach(groups) { group in
            let items = viewModel?.listsInGroup(group) ?? []
            Section {
                DisclosureGroup(isExpanded: Binding(
                    get: { viewModel?.isGroupExpanded(group) ?? false },
                    set: { _ in viewModel?.toggleGroupExpanded(group) }
                )) {
                    ForEach(items) { list in
                        listNavigationLink(for: list)
                    }
                    .onMove { fromOffsets, toOffset in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel?.moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: items, group: group)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.colors.textSecondary)
                        Text(group.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.colors.textPrimary)
                        Spacer()
                        Text("\(items.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppTheme.colors.fillSubtle)
                            .clipShape(Capsule())
                    }
                    .contextMenu {
                        Button("Rename") {
                            viewModel?.groupRenameText = group.name
                            viewModel?.renameGroup = group
                            viewModel?.isGroupRenamePresented = true
                        }
                        Button("Delete Group", role: .destructive) {
                            viewModel?.deleteGroup = group
                        }
                    }
                }
            }
        }
    }

    // MARK: - List Navigation Link

    private func listNavigationLink(for list: ReminderList) -> some View {
        NavigationLink {
            ListDetailView(listID: list.persistentModelID)
        } label: {
            listRow(list: list)
        }
        .contextMenu {
            contextMenuItems(for: list)
        }
    }

    // MARK: - Context Menu Items

    @ViewBuilder
    private func contextMenuItems(for list: ReminderList) -> some View {
        if list.name != ReminderDefaults.defaultListName {
            Button("Rename") {
                viewModel?.renameList = list
                viewModel?.renameText = list.name
                viewModel?.isRenamePresented = true
            }

            Button("Create New Group") {
                viewModel?.newGroupName = ""
                viewModel?.groupSourceList = list
                viewModel?.isCreatingGroup = true
            }

            if !groups.isEmpty {
                Menu("Move to Group") {
                    if list.group != nil {
                        Button("None") {
                            viewModel?.assignListToGroup(list, group: nil)
                        }
                    }
                    ForEach(groups) { group in
                        if group.persistentModelID != list.group?.persistentModelID {
                            Button(group.name) {
                                viewModel?.assignListToGroup(list, group: group)
                            }
                        }
                    }
                    Button("New Group...") {
                        viewModel?.newGroupName = ""
                        viewModel?.groupSourceList = list
                        viewModel?.isCreatingGroup = true
                    }
                }
            }

            Button("Delete List", role: .destructive) {
                viewModel?.requestDeleteList(list)
            }
        }
    }

    // MARK: - Helpers

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
