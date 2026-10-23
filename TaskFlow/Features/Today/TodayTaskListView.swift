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

    var body: some View {
        NavigationStack {
            content
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
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        filterMenu
                    }
                }
                .navigationDestination(item: $editingTask) { task in
                    ReminderEditorView(task: task, embedInNavigationStack: false)
                }
        }
        .onAppear(perform: bootstrap)
        .onChange(of: groups) { _, _ in refresh() }
        .onChange(of: allTasks) { _, _ in refresh() }
        .onChange(of: editingTask) { _, task in
            if task == nil { refresh() }
        }
        .sheet(item: $newTaskConfig) { config in
            ReminderEditorView(initialDate: config.initialDate, initialListID: config.initialListID)
        }
    }

    /// New tasks land in the Work inbox unless another area's Inbox exists.
    private var defaultListID: ReminderList.ID? {
        (
            lists.first { $0.isBucket && $0.group?.name == AreaNames.work }
            ?? lists.first { $0.isBucket }
            ?? lists.first
        )?.persistentModelID
    }

    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: filterBinding) {
                ForEach(viewModel?.filterOptions ?? [.all]) { option in
                    Label(option.title, systemImage: option.icon)
                        .tag(option.filter)
                }
            }
            .pickerStyle(.inline)
        } label: {
            if !(viewModel?.isFilteringByArea ?? false) {
                Image(
                    systemName: "line.3.horizontal.decrease"
                )
                .foregroundStyle(AppTheme.colors.textPrimary)
                .frame(width: 32, height: 32)
            } else {
                Image(
                    systemName: "line.3.horizontal.decrease.circle.fill"
                )
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.colors.tint)
                .frame(width: 32, height: 32)
            }
        }
        .accessibilityLabel("Filter")
    }

    private var filterBinding: Binding<TodayAreaFilter> {
        Binding(
            get: { viewModel?.areaFilter ?? .all },
            set: { viewModel?.selectFilter($0) }
        )
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
                        showsGroupName: !(viewModel?.isFilteringByArea ?? false),
                        groupNameOverride: groupName(for: task)
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
        guard viewModel?.isFilteringByArea == true else {
            return "Nothing due today"
        }
        return "No \(viewModel?.selectedFilterTitle.lowercased() ?? "") tasks due today"
    }

    private var emptyDescription: String {
        guard viewModel?.isFilteringByArea == true else {
            return "Tasks due today or overdue will appear here."
        }
        return "\(viewModel?.selectedFilterTitle ?? "") tasks due today or overdue will appear here."
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
            if name == "Personal" || name == "Home" { return "Home" }
        }
        if let listName = task.reminderList?.name {
            let name = listName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name == "Work" { return "Work" }
            if name == "Personal" || name == "Home" { return "Home" }
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
