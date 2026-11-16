import SwiftUI
import SwiftData

struct TodayTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]

    @State private var viewModel: TodayViewModel?
    @State private var editingTask: TaskItem?
    @State private var newTaskConfig: NewTaskSheetConfig?
    @State private var lastHandledTodayResetID = 0

    private let embedInNavigationStack: Bool

    init(embedInNavigationStack: Bool = true) {
        self.embedInNavigationStack = embedInNavigationStack
    }

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        Group {
            if embedInNavigationStack {
                NavigationStack {
                    navigationContent
                }
            } else {
                navigationContent
            }
        }
        .onAppear {
            bootstrap()
            syncTodayState()
            handleTodayResetIfNeeded()
        }
        .onChange(of: appState.todayResetRequestID) { _, _ in
            handleTodayResetIfNeeded()
        }
        .onChange(of: groups) { _, _ in refreshViewModel() }
        .onChange(of: allTasks) { _, _ in refreshViewModel() }
        .onChange(of: editingTask) { _, task in
            if task == nil { refreshViewModel() }
        }
        .sheet(item: $newTaskConfig) { config in
            ReminderEditorView(initialDate: config.initialDate, initialListID: config.initialListID)
        }
    }

    private var navigationContent: some View {
        content
            .background(AppTheme.colors.pageBackground.ignoresSafeArea())
            .overlay(alignment: .top) {
                if let pending = viewModel?.pendingUndo {
                    UndoToast(title: pending.task.safeTitle) {
                        viewModel?.undoCompletion()
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingAddButton {
                    newTaskConfig = NewTaskSheetConfig(
                        initialDate: calendar.startOfDay(for: Date()),
                        initialListID: defaultListID
                    )
                }
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel?.pendingUndo?.id)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $editingTask) { task in
                ReminderEditorView(task: task, embedInNavigationStack: false)
            }
    }

    private var defaultListID: ReminderList.ID? {
        lists.first(where: { $0.isBucket })?.persistentModelID ?? lists.first?.persistentModelID
    }

    private func isWorkDomain(_ name: String?) -> Bool {
        name == AreaNames.work
    }

    private func isPersonalDomain(_ name: String?) -> Bool {
        name == AreaNames.personal || name == "Home"
    }

    @ViewBuilder
    private var content: some View {
        let tasks = viewModel?.visibleTasks ?? []
        let workTasks = tasks.filter { isWorkDomain($0.reminderList?.group?.name) }
        let personalTasks = tasks.filter { isPersonalDomain($0.reminderList?.group?.name) }

        if workTasks.isEmpty && personalTasks.isEmpty {
            ContentUnavailableView(
                "No tasks for today",
                systemImage: "checklist",
                description: Text("Due-today and overdue tasks from Work and Personal will appear here.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if !workTasks.isEmpty {
                        taskSection(title: "Work", tasks: workTasks)
                    }
                    if !personalTasks.isEmpty {
                        taskSection(title: "Personal", tasks: personalTasks)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .refreshable { refreshViewModel() }
        }
    }

    @ViewBuilder
    private func taskSection(title: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    TaskRowView(
                        task: task,
                        isCompletedVisualState: task.isCompleted ?? false,
                        onToggleCompletion: {
                            Haptics.impact(.light)
                            viewModel?.toggleCompletion(for: task)
                        },
                        onDelete: { viewModel?.delete(task) },
                        onTap: { editingTask = task },
                        showsDueDate: viewModel?.isOverdue(task) == true,
                        showsListName: true,
                        showsRowBackground: false
                    )

                    if index < tasks.count - 1 {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func bootstrap() {
        if viewModel == nil {
            viewModel = TodayViewModel(modelContext: modelContext)
        }
    }

    private func syncTodayState() {
        viewModel?.selectDate(calendar.startOfDay(for: Date()))
        viewModel?.selectFilter(.all)
        refreshViewModel()
    }

    private func handleTodayResetIfNeeded() {
        guard appState.todayResetRequestID != lastHandledTodayResetID else { return }
        lastHandledTodayResetID = appState.todayResetRequestID
        syncTodayState()
    }

    private func refreshViewModel() {
        viewModel?.selectFilter(.all)
        viewModel?.update(groups: groups, allTasks: allTasks, now: Date())
    }
}

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return TodayTaskListView()
        .modelContainer(container)
        .environment(AppState())
}
