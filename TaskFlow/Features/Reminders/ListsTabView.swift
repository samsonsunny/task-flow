import SwiftUI
import SwiftData

struct ListsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    let onSettings: () -> Void

    @State private var isCreatingList = false
    @State private var newListName = ""

    @State private var isRenamePresented = false
    @State private var renameList: ReminderList?
    @State private var renameText = ""

    @State private var deleteList: ReminderList?

    @State private var isCreatingGroup = false
    @State private var newGroupName = ""
    @State private var groupSourceList: ReminderList?

    @State private var renameGroup: ReminderListGroup?
    @State private var isGroupRenamePresented = false
    @State private var groupRenameText = ""

    @State private var deleteGroup: ReminderListGroup?

    @State private var expandedGroupIDs: Set<PersistentIdentifier> = Set()

    private let defaultsKeyPrefix = "list-group-expanded-"

    private var defaultList: ReminderList? {
        lists.first(where: { $0.name == ReminderDefaults.defaultListName })
    }

    private var ungroupedLists: [ReminderList] {
        lists.filter { $0.group == nil && $0.name != ReminderDefaults.defaultListName }
    }

    var body: some View {
        NavigationStack {
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
                    newListName = ""
                    isCreatingList = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .alert("New List", isPresented: $isCreatingList) {
                TextField("List Name", text: $newListName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let list = ReminderList(name: name)
                    modelContext.insert(list)
                    list.assignInitialSortOrder(in: modelContext)
                }
            }
            .alert("New Group", isPresented: $isCreatingGroup) {
                TextField("Group Name", text: $newGroupName)
                Button("Cancel", role: .cancel) {
                    groupSourceList = nil
                }
                Button("Create") {
                    let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let group = ReminderListGroup(name: name)
                    modelContext.insert(group)
                    group.assignInitialSortOrder(in: modelContext)
                    if let sourceList = groupSourceList {
                        sourceList.group = group
                    }
                    groupSourceList = nil
                    try? modelContext.save()
                }
            }
            .alert("Rename List", isPresented: $isRenamePresented) {
                TextField("List Name", text: $renameText)
                Button("Cancel", role: .cancel) {
                    renameList = nil
                }
                Button("Rename") {
                    guard let list = renameList else { return }
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    list.name = trimmed
                    try? modelContext.save()
                    renameList = nil
                }
            }
            .alert("Rename Group", isPresented: $isGroupRenamePresented) {
                TextField("Group Name", text: $groupRenameText)
                Button("Cancel", role: .cancel) {
                    renameGroup = nil
                }
                Button("Rename") {
                    guard let group = renameGroup else { return }
                    let trimmed = groupRenameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    group.name = trimmed
                    try? modelContext.save()
                    renameGroup = nil
                }
            }
            .alert("Delete Group", isPresented: Binding(
                get: { deleteGroup != nil },
                set: { if !$0 { deleteGroup = nil } }
            )) {
                Button("Delete Group & Lists", role: .destructive) {
                    handleDeleteGroup()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let group = deleteGroup {
                    Text("Delete \"\(group.name)\" and all lists inside? This cannot be undone.")
                }
            }
            .alert("Delete List", isPresented: Binding(
                get: { deleteList != nil },
                set: { if !$0 { deleteList = nil } }
            )) {
                Button("Move tasks to Reminders") {
                    handleDelete(moveTasks: true)
                }
                Button("Delete All Tasks", role: .destructive) {
                    handleDelete(moveTasks: false)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let list = deleteList {
                    Text("What should happen to the tasks in \"\(list.name)\"?")
                }
            }
        }
    }

    // MARK: - Default List Section

    private var defaultListSection: some View {
        Section {
            if let defaultList {
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
        let items = ungroupedLists
        return Group {
            if !items.isEmpty {
                Section {
                    ForEach(items) { list in
                        listNavigationLink(for: list)
                    }
                    .onMove { fromOffsets, toOffset in
                        moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: items)
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
            let items = lists.filter { $0.group?.persistentModelID == group.persistentModelID }
            Section {
                DisclosureGroup(isExpanded: Binding(
                    get: { expandedGroupIDs.contains(group.persistentModelID) },
                    set: { expanded in
                        if expanded {
                            expandedGroupIDs.insert(group.persistentModelID)
                        } else {
                            expandedGroupIDs.remove(group.persistentModelID)
                        }
                        UserDefaults.standard.set(expanded, forKey: defaultsKeyPrefix + group.persistentModelID.hashValue.description)
                    }
                )) {
                    ForEach(items) { list in
                        listNavigationLink(for: list)
                    }
                    .onMove { fromOffsets, toOffset in
                        moveLists(fromOffsets: fromOffsets, toOffset: toOffset, in: items, group: group)
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
                            groupRenameText = group.name
                            renameGroup = group
                            isGroupRenamePresented = true
                        }
                        Button("Delete Group", role: .destructive) {
                            deleteGroup = group
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
                renameList = list
                renameText = list.name
                isRenamePresented = true
            }

            Button("Create New Group") {
                newGroupName = ""
                groupSourceList = list
                isCreatingGroup = true
            }

            if !groups.isEmpty {
                Menu("Move to Group") {
                    if list.group != nil {
                        Button("None") {
                            list.group = nil
                            try? modelContext.save()
                        }
                    }
                    ForEach(groups) { group in
                        if group.persistentModelID != list.group?.persistentModelID {
                            Button(group.name) {
                                list.group = group
                                try? modelContext.save()
                            }
                        }
                    }
                    Button("New Group...") {
                        newGroupName = ""
                        groupSourceList = list
                        isCreatingGroup = true
                    }
                }
            }

            Button("Delete List", role: .destructive) {
                let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }
                if listTasks.isEmpty {
                    modelContext.delete(list)
                    try? modelContext.save()
                } else {
                    deleteList = list
                }
            }
        }
    }

    // MARK: - Helpers

    private func handleDelete(moveTasks: Bool) {
        guard let list = deleteList else { return }
        deleteList = nil

        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }

        if moveTasks {
            if let defaultList {
                for task in listTasks {
                    task.reminderList = defaultList
                }
            }
        } else {
            for task in listTasks {
                if let taskId = task.taskId {
                    NotificationService.shared.cancel(taskId: taskId)
                }
                modelContext.delete(task)
            }
        }

        modelContext.delete(list)
        try? modelContext.save()
    }

    private func handleDeleteGroup() {
        guard let group = deleteGroup else { return }
        deleteGroup = nil

        let groupLists = lists.filter { $0.group?.persistentModelID == group.persistentModelID }
        for list in groupLists {
            let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }
            for task in listTasks {
                if let taskId = task.taskId {
                    NotificationService.shared.cancel(taskId: taskId)
                }
                modelContext.delete(task)
            }
            modelContext.delete(list)
        }
        modelContext.delete(group)
        try? modelContext.save()
    }

    private func moveLists(fromOffsets: IndexSet, toOffset: Int, in source: [ReminderList], group: ReminderListGroup? = nil) {
        withAnimation(.easeInOut(duration: 0.18)) {
            var mutableLists = source
            let sortedFrom = fromOffsets.sorted()

            let moved = sortedFrom.reversed().map { mutableLists.remove(at: $0) }
            let adjustedTo = toOffset > sortedFrom.first! ? toOffset - moved.count : toOffset
            let insertAt = min(adjustedTo, mutableLists.count)

            mutableLists.insert(contentsOf: moved, at: insertAt)

            var lower = insertAt > 0 ? mutableLists[insertAt - 1].sortOrder : nil
            for i in insertAt..<(insertAt + moved.count) {
                let upper = (i + 1) < mutableLists.count ? mutableLists[i + 1].sortOrder : nil

                if let newOrder = midpoint(between: lower, and: upper) {
                    mutableLists[i].sortOrder = newOrder
                } else {
                    if let upperStr = upper {
                        let widened = widen(upperStr)
                        if let upperList = mutableLists.first(where: { $0.sortOrder == upperStr }) {
                            upperList.sortOrder = widened
                        }
                        mutableLists[i].sortOrder = midpoint(between: lower, and: widened) ?? ""
                    } else {
                        mutableLists[i].sortOrder = ""
                    }
                }

                lower = mutableLists[i].sortOrder
            }

            if let group {
                for list in mutableLists {
                    list.group = group
                }
            }

            try? modelContext.save()
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
