import SwiftUI
import SwiftData

struct TodayTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]

    @State private var viewModel: TodayViewModel?
    @State private var editingTask: TaskItem?
    @State private var newTaskConfig: NewTaskSheetConfig?
    @State private var selectedSegment: TodaySegment = .work

    enum TodaySegment: String, CaseIterable {
        case work = "Work"
        case personal = "Personal"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Area", selection: $selectedSegment) {
                    ForEach(TodaySegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                content
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingAddButton {
                    newTaskConfig = NewTaskSheetConfig(
                        initialDate: Date(),
                        initialListID: defaultListID
                    )
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if let pending = viewModel?.pendingUndo {
                    UndoToast(title: pending.task.safeTitle) {
                        viewModel?.undoCompletion()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel?.pendingUndo?.id)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $editingTask) { task in
                ReminderEditorView(task: task, embedInNavigationStack: false)
            }
        }
        .onAppear {
            bootstrap()
            updateFilterForSegment()
        }
        .onChange(of: groups) { _, _ in
            refresh()
            updateFilterForSegment()
        }
        .onChange(of: allTasks) { _, _ in refresh() }
        .onChange(of: editingTask) { _, task in
            if task == nil { refresh() }
        }
        .onChange(of: selectedSegment) { _, _ in
            updateFilterForSegment()
        }
        .sheet(item: $newTaskConfig) { config in
            ReminderEditorView(initialDate: config.initialDate, initialListID: config.initialListID)
        }
    }

    /// New tasks land in the selected area's inbox.
    private var defaultListID: ReminderList.ID? {
        let targetName = selectedSegment == .work ? AreaNames.work : AreaNames.personal
        if let inbox = lists.first(where: { $0.isBucket && ($0.group?.name == targetName || ($0.group?.name == "Home" && targetName == AreaNames.personal)) }) {
            return inbox.persistentModelID
        }
        if let group = groups.first(where: { $0.name == targetName || ($0.name == "Home" && targetName == AreaNames.personal) }) {
            if let inbox = lists.first(where: { $0.isBucket && $0.group?.persistentModelID == group.persistentModelID }) {
                return inbox.persistentModelID
            }
        }
        if targetName == AreaNames.work {
            if let inbox = lists.first(where: { $0.isBucket && $0.group?.name == AreaNames.work }) {
                return inbox.persistentModelID
            }
        }
        return lists.first(where: { $0.isBucket })?.persistentModelID ?? lists.first?.persistentModelID
    }

    private func updateFilterForSegment() {
        guard let viewModel else { return }
        let targetName = selectedSegment == .work ? AreaNames.work : AreaNames.personal
        if let group = groups.first(where: { $0.name == targetName || ($0.name == "Home" && targetName == AreaNames.personal) }) {
            viewModel.selectFilter(.area(group.persistentModelID))
        } else if let group = groups.first(where: { $0.isLocked }) {
            let name = group.name
            if name == AreaNames.work && selectedSegment == .work {
                viewModel.selectFilter(.area(group.persistentModelID))
            } else if (name == AreaNames.personal || name == "Home") && selectedSegment == .personal {
                viewModel.selectFilter(.area(group.persistentModelID))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let sections = viewModel?.sections ?? []
        if sections.isEmpty {
            ContentUnavailableView(
                emptyTitle,
                systemImage: "sun.max",
                description: Text(emptyDescription)
            )
        } else {
            List {
                ForEach(viewModel?.sections.flatMap { $0.tasks } ?? []) { task in
                    TaskRowView(
                        task: task,
                        isCompletedVisualState: task.isCompleted ?? false,
                        onToggleCompletion: { viewModel?.toggleCompletion(for: task) },
                        onDelete: { viewModel?.delete(task) },
                        onTap: { editingTask = task },
                        showsDueDate: true,
                        showsListName: true,
                        showsGroupName: false,
                        groupNameOverride: nil
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .contentMargins(.bottom, 88, for: .scrollContent)
            .refreshable { refresh() }
        }
    }

    private var emptyTitle: String {
        return "No \(selectedSegment.rawValue.lowercased()) tasks due today"
    }

    private var emptyDescription: String {
        return "\(selectedSegment.rawValue) tasks due today or overdue will appear here."
    }

    private func bootstrap() {
        if viewModel == nil {
            viewModel = TodayViewModel(modelContext: modelContext)
        }
        refresh()
    }

    private func refresh() {
        viewModel?.update(groups: groups, allTasks: allTasks, now: Date())
    }

    private func groupName(for task: TaskItem) -> String? {
        if let group = task.reminderList?.group {
            let name = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name == "Work" { return "Work" }
            if name == "Personal" || name == "Home" { return "Personal" }
        }
        if let listName = task.reminderList?.name {
            let name = listName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name == "Work" { return "Work" }
            if name == "Personal" || name == "Home" { return "Personal" }
        }
        return nil
    }
}

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return TodayTaskListView()
        .modelContainer(container)
        .environment(AppState())
}
