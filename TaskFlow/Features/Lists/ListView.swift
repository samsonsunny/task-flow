import SwiftUI
import SwiftData

struct ListsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    let onSettings: () -> Void

    @State private var viewModel: ListsTabViewModel?
    @State private var showListCreationSheet = false
    @State private var showGroupCreationSheet = false
    @State private var groupCreationSourceList: ReminderList?
    @State private var capturingGroupID: PersistentIdentifier?
    @State private var captureText = ""
    @FocusState private var isCaptureFocused: Bool

    var body: some View {
        NavigationStack {
            alertsContainer
        }
    }

    private var listContent: some View {
        ScrollViewReader { proxy in
            List {
                defaultListSection
                ungroupedSection
                groupSections
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.colors.appBackground)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: capturingGroupID) { _, id in
                if id != nil {
                    DispatchQueue.main.async {
                        withAnimation { proxy.scrollTo("group-list-capture", anchor: .bottom) }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                guard capturingGroupID != nil else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("group-list-capture", anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .quickCaptureCommitted)) { _ in
                guard capturingGroupID != nil else { return }
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("group-list-capture", anchor: .bottom)
                    }
                }
            }
        }
        .navigationTitle("Later")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onSettings()
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
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
            .alert("Delete List", isPresented: Binding(
                get: { viewModel?.deleteList != nil },
                set: { if !$0 { viewModel?.deleteList = nil } }
            )) {
                Button("Move tasks to Inbox") {
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
                .accessibilityIdentifier("default-list-link")
                .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        } header: {
            HStack {
                Text("Inbox")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                Spacer()
            }
        }
    }

    // MARK: - Ungrouped Lists Section

    private var ungroupedSection: some View {
        let items = viewModel?.ungroupedLists ?? []
        return Section {
            ForEach(items) { list in
                listNavigationLink(for: list)
            }
            .onMove { fromOffsets, toOffset in
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel?.moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: items)
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.primaryAction)
                }
                .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Group Sections

    private var groupSections: some View {
        Section {
            ForEach(Array(groups.enumerated()), id: \.element.persistentModelID) { index, group in
                let items = viewModel?.listsInGroup(group) ?? []
                DisclosureGroup(isExpanded: Binding(
                    get: { viewModel?.isGroupExpanded(group) ?? false },
                    set: { expanded in
                        viewModel?.toggleGroupExpanded(group)
                        if !expanded && capturingGroupID == group.persistentModelID {
                            capturingGroupID = nil
                        }
                    }
                )) {
                    ForEach(items) { list in
                        listNavigationLink(for: list)
                    }
                    .onMove { fromOffsets, toOffset in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel?.moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: items, group: group)
                        }
                    }
                    groupListCaptureRow(for: group)
                } label: {
                    HStack {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.colors.textSecondary)
                        Text(group.name)
                            .font(.system(size: 17, weight: .semibold))
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
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove { fromOffsets, toOffset in
                withAnimation(.easeInOut(duration: 0.18)) {
                    viewModel?.moveGroups(fromOffsets: fromOffsets, toOffset: toOffset)
                }
            }

            newGroupRow
        } header: {
            HStack {
                Text("Groups")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                Spacer()
                Button {
                    groupCreationSourceList = nil
                    showGroupCreationSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.primaryAction)
                }
                .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Inline Creation Rows

    private var newListRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 20, height: 20)

            Text("New List")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.colors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            showListCreationSheet = true
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .accessibilityIdentifier("new-list-row")
    }

    private var newGroupRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 20, height: 20)

            Text("New Group")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.colors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            groupCreationSourceList = nil
            showGroupCreationSheet = true
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .accessibilityIdentifier("new-group-row")
    }

    @ViewBuilder
    private func groupListCaptureRow(for group: ReminderListGroup) -> some View {
        if capturingGroupID == group.persistentModelID {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.colors.primaryAction)
                    .frame(width: 20, height: 20)

                NonDismissingTextField(
                    text: $captureText,
                    placeholder: "New List",
                    onSubmit: {
                        let t = captureText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else {
                            isCaptureFocused = false
                            return
                        }
                        viewModel?.createList(name: captureText, group: group)
                        viewModel?.update(lists: lists, groups: groups, allTasks: allTasks)
                        captureText = ""
                        NotificationCenter.default.post(name: .quickCaptureCommitted, object: nil)
                    },
                    isFocused: $isCaptureFocused
                )
                .onChange(of: isCaptureFocused) { _, focused in
                    if !focused {
                        capturingGroupID = nil
                    }
                }
            }
            .padding(.vertical, 9)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
            .id("group-list-capture")
        } else {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .frame(width: 20, height: 20)

                Text("New List")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textSecondary)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
            .onTapGesture {
                captureText = ""
                capturingGroupID = group.persistentModelID
                DispatchQueue.main.async {
                    isCaptureFocused = true
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        }
    }

    // MARK: - List Navigation Link

    private func listNavigationLink(for list: ReminderList) -> some View {
        NavigationLink {
            ListDetailView(listID: list.persistentModelID)
        } label: {
            listRow(list: list)
        }
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
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
        let isInbox = list.name == ReminderDefaults.defaultListName

        return HStack(spacing: 12) {
            Image(systemName: isInbox ? "tray" : "list.bullet")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 24)

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
