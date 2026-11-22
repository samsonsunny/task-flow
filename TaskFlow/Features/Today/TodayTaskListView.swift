import SwiftUI
import SwiftData

/// The two fixed domains surfaced as Today sections. Layout-only: tasks themselves stay
/// owned by the ViewModel and are split by their list's group name.
private enum TodayDomain: String {
    case work
    case personal

    var title: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        }
    }

    var areaName: String {
        switch self {
        case .work: return AreaNames.work
        case .personal: return AreaNames.personal
        }
    }
}

struct TodayTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]

    @State private var viewModel: TodayViewModel?
    @State private var editingTask: TaskItem?
    @State private var newTaskConfig: NewTaskSheetConfig?
    @State private var scheduleConfigTask: TaskItem?
    @State private var lastHandledTodayResetID = 0
    /// Sections a person expanded with "More". UI-only state: a section stays expanded
    /// for the current page state, and there is no collapse control.
    @State private var expandedDomains: Set<TodayDomain> = []

    /// Rows shown per domain before its "More" control reveals the rest.
    private static let initialTaskLimit = 5
    private static let sectionSpacing: CGFloat = 20

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
        .sheet(item: $scheduleConfigTask) { task in
            TaskScheduleDatePickerSheet(
                isPresented: Binding(
                    get: { scheduleConfigTask != nil },
                    set: { if !$0 { scheduleConfigTask = nil } }
                ),
                initialDueDate: task.dueDate,
                initialFocus: task.dueDate == nil ? .date : .time,
                onCommit: { dueDate, hasTime in
                    viewModel?.scheduleTask(task, dueDate: dueDate, hasTime: hasTime)
                }
            )
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

    private func tasks(for domain: TodayDomain, from all: [TaskItem]) -> [TaskItem] {
        all.filter { task in
            let name = task.reminderList?.group?.name
            switch domain {
            case .work: return name == AreaNames.work
            case .personal: return name == AreaNames.personal || name == "Home"
            }
        }
    }

    /// Each section creates into its own domain's Inbox, never the other domain's.
    private func inboxListID(for domain: TodayDomain) -> ReminderList.ID? {
        guard let group = groups.first(where: { $0.name == domain.areaName }) else { return nil }
        return group.inboxBucket?.persistentModelID
    }

    private func addTask(for domain: TodayDomain) {
        newTaskConfig = NewTaskSheetConfig(
            initialDate: calendar.startOfDay(for: Date()),
            initialListID: inboxListID(for: domain)
        )
    }

    @ViewBuilder
    private var content: some View {
        let visible = viewModel?.visibleTasks ?? []
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Self.sectionSpacing) {
                if visible.isEmpty {
                    ContentUnavailableView(
                        "No tasks for today",
                        systemImage: "checklist",
                        description: Text("Due-today and overdue tasks from Work and Personal will appear here.")
                    )
                    .frame(maxWidth: .infinity)
                }
                domainSection(.work, tasks: tasks(for: .work, from: visible))
                domainSection(.personal, tasks: tasks(for: .personal, from: visible))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .refreshable { refreshViewModel() }
    }

    @ViewBuilder
    private func domainSection(_ domain: TodayDomain, tasks: [TaskItem]) -> some View {
        let isExpanded = expandedDomains.contains(domain)
        let shown = isExpanded ? tasks : Array(tasks.prefix(Self.initialTaskLimit))
        let hasMore = shown.count < tasks.count

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(domain.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.colors.textSecondary)
                Spacer(minLength: 0)
                addTaskButton(for: domain)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                if shown.isEmpty {
                    Text("Nothing due today")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                } else {
                    taskRows(
                        shown,
                        domain: domain,
                        hasMore: hasMore,
                        onMore: { expand(domain) }
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .accessibilityIdentifier("today-section-\(domain.rawValue)")
    }

    @ViewBuilder
    private func taskRows(
        _ rows: [TaskItem],
        domain: TodayDomain,
        hasMore: Bool,
        onMore: @escaping () -> Void
    ) -> some View {
        ForEach(Array(rows.enumerated()), id: \.element.id) { index, task in
            // The "More" control is an overlay on the last row, not its own row. It only
            // occupies its own frame, so the row's completion, tap and menu gestures stay
            // available everywhere else.
            ZStack(alignment: .bottomTrailing) {
                TaskRowView(
                    task: task,
                    isCompletedVisualState: task.isCompleted ?? false,
                    onToggleCompletion: {
                        Haptics.impact(.light)
                        viewModel?.toggleCompletion(for: task)
                    },
                    onDueDateAction: { action in
                        if action == .custom {
                            scheduleConfigTask = task
                        } else {
                            viewModel?.rescheduleTask(task, to: action)
                        }
                    },
                    onDelete: { viewModel?.delete(task) },
                    onTap: { editingTask = task },
                    showsDueDate: viewModel?.isOverdue(task) == true,
                    showsListName: true,
                    showsRowBackground: false
                )

                if hasMore && index == rows.count - 1 {
                    moreControl(domain: domain, action: onMore)
                }
            }

            if index < rows.count - 1 {
                Divider()
                    .padding(.leading, 54)
            }
        }
    }

    private func moreControl(domain: TodayDomain, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Text("More")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.colors.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 12)
        .padding(.bottom, 8)
        .accessibilityLabel("More \(domain.title) tasks")
        .accessibilityIdentifier("today-more-\(domain.rawValue)")
    }

    private func expand(_ domain: TodayDomain) {
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = expandedDomains.insert(domain)
        }
    }

    private func addTaskButton(for domain: TodayDomain) -> some View {
        Button {
            addTask(for: domain)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.colors.tint)
                .frame(width: 28, height: 28)
                .background(AppTheme.colors.tint.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(domain.title) task")
        .accessibilityIdentifier("today-add-\(domain.rawValue)")
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
