import SwiftUI
import SwiftData

struct ListsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    let headerAccessory: (() -> AnyView)?

    init(headerAccessory: (() -> AnyView)? = nil) {
        self.headerAccessory = headerAccessory
    }

    @State private var viewModel: ListsTabViewModel?
    @State private var showListCreationSheet = false
    @State private var showGroupCreationSheet = false
    @State private var groupCreationSourceList: ReminderList?
    @State private var listToDeleteAll: ReminderList?
    @State private var showDeleteAllAlert = false

    var body: some View {
        alertsContainer
    }

    private var listContent: some View {
        List {
            if let headerAccessory = headerAccessory {
                headerAccessory()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            listsSection
        }
        .listStyle(.plain)
        .listSectionSpacing(0)
        .listRowSpacing(0)
        .contentMargins(.top, 0, for: .scrollContent)
        .contentMargins(.bottom, 72, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var alertsContainer: some View {
        listContent
            .sheet(isPresented: $showListCreationSheet) {
                ListCreationSheet(
                    modelContext: modelContext,
                    onCreate: { name, group in
                        viewModel?.createList(name: name, group: group)
                        viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
                    }
                )
            }
            .sheet(isPresented: $showGroupCreationSheet) {
                GroupCreationSheet(
                    modelContext: modelContext,
                    initialList: groupCreationSourceList,
                    onCreate: { name, sourceList in
                        viewModel?.createGroup(name: name, sourceList: sourceList)
                        viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
                    }
                )
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
            .alert("Delete All Tasks", isPresented: $showDeleteAllAlert) {
                Button("Delete", role: .destructive) {
                    if let list = listToDeleteAll {
                        viewModel?.deleteListAndTasks(list)
                    }
                    listToDeleteAll = nil
                }
                Button("Cancel", role: .cancel) {
                    listToDeleteAll = nil
                }
            } message: {
                if let list = listToDeleteAll {
                    Text("Delete all tasks in \"\(list.name)\"? This cannot be undone.")
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

    // MARK: - Lists Section

    private var listsSection: some View {
        let ungroupedItems = viewModel?.ungroupedLists ?? []
        return Section {
            ForEach(ungroupedItems) { list in
                listNavigationLink(for: list)
            }
            .onMove { fromOffsets, toOffset in
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel?.moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: ungroupedItems)
                }
            }

            ForEach(groups) { group in
                let items = viewModel?.listsInGroup(group) ?? []
                DisclosureGroup {
                    ForEach(items) { list in
                        listNavigationLink(for: list)
                    }
                    .onMove { fromOffsets, toOffset in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel?.moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: items, group: group)
                        }
                    }
                } label: {
                    groupHeaderRow(for: group, count: items.count)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove { fromOffsets, toOffset in
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel?.moveGroups(fromOffsets: fromOffsets, toOffset: toOffset)
                }
            }

            newListRow
        } header: {
            HStack {
                Text("Lists")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                Spacer()
                Button {
                    showListCreationSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.textSecondary)
                }
                .contentShape(Rectangle())
            }
        }
    }

    private func groupHeaderRow(for group: ReminderListGroup, count: Int) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.colors.textSecondary)
            Text(group.name)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.colors.textPrimary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(AppTheme.colors.fillSubtle)
                .clipShape(Capsule())
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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

    // MARK: - Inline Creation Rows

    private var newListRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.colors.textSecondary)

            Text("New List")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.colors.textSecondary)

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showListCreationSheet = true
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityIdentifier("new-list-row")
    }

    // MARK: - List Navigation Link

    private func listNavigationLink(for list: ReminderList) -> some View {
        NavigationLink {
            ListDetailView(listID: list.persistentModelID)
        } label: {
            listRow(list: list)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .contextMenu {
            contextMenuItems(for: list)
        }
        .swipeActions(edge: .trailing) {
            if list.name != ReminderDefaults.defaultListName {
                let hasTasks = allTasks.contains(where: { $0.reminderList?.persistentModelID == list.persistentModelID })
                let destinations = availableListsForMove(excluding: list)

                if hasTasks && !destinations.isEmpty {
                    Menu {
                        Menu("Move to list") {
                            moveToListMenuContent(for: list)
                        }
                        Divider()
                        Button("Delete All Tasks", role: .destructive) {
                            listToDeleteAll = list
                            showDeleteAllAlert = true
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                } else {
                    Button(role: .destructive) {
                        viewModel?.deleteListAndTasks(list)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
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
                groupCreationSourceList = list
                showGroupCreationSheet = true
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
                        groupCreationSourceList = list
                        showGroupCreationSheet = true
                    }
                }
            }

            let hasTasks = allTasks.contains(where: { $0.reminderList?.persistentModelID == list.persistentModelID })
            let destinations = availableListsForMove(excluding: list)

            if hasTasks && !destinations.isEmpty {
                Menu("Move to list") {
                    moveToListMenuContent(for: list)
                }
                Button("Delete All Tasks", role: .destructive) {
                    listToDeleteAll = list
                    showDeleteAllAlert = true
                }
            } else {
                Button("Delete List", role: .destructive) {
                    viewModel?.deleteListAndTasks(list)
                }
            }
        }
    }

    // MARK: - Helpers

    private func availableListsForMove(excluding: ReminderList) -> [ReminderList] {
        lists.filter { $0.persistentModelID != excluding.persistentModelID }
    }

    @ViewBuilder
    private func moveToListMenuContent(for source: ReminderList) -> some View {
        let destinations = availableListsForMove(excluding: source)
        let inboxList = destinations.first { $0.name == ReminderDefaults.defaultListName }
        let ungrouped = destinations.filter { $0.group == nil && $0.name != ReminderDefaults.defaultListName }

        if let inbox = inboxList {
            Button(inbox.name) {
                viewModel?.deleteList(source, moveTasksTo: inbox)
            }
        }

        ForEach(groups) { group in
            let groupLists = destinations.filter { $0.group?.persistentModelID == group.persistentModelID }
            if !groupLists.isEmpty {
                Divider()
                Text(group.name)
                ForEach(groupLists) { target in
                    Button(target.name) {
                        viewModel?.deleteList(source, moveTasksTo: target)
                    }
                }
            }
        }

        if !ungrouped.isEmpty {
            Divider()
            Text("Lists")
            ForEach(ungrouped) { target in
                Button(target.name) {
                    viewModel?.deleteList(source, moveTasksTo: target)
                }
            }
        }
    }

    private func listRow(list: ReminderList) -> some View {
        let count = allTasks.filter {
            $0.reminderList?.persistentModelID == list.persistentModelID && $0.isCompleted != true
        }.count
        let isInbox = list.name == ReminderDefaults.defaultListName

        return HStack(spacing: 16) {
            Image(systemName: isInbox ? "tray" : "list.bullet")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.colors.textSecondary)

            Text(list.name)
                .font(.system(size: 17))
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
    }
}
