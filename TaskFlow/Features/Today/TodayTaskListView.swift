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

    private var rowActions: TaskRowActions {
        TaskRowActions(
            toggleCompletion: { viewModel?.toggleCompletion(for: $0) },
            reschedule: { task, action in
                if action == .custom {
                    scheduleConfigTask = task
                } else {
                    viewModel?.rescheduleTask(task, to: action)
                }
            },
            delete: { viewModel?.delete($0) },
            open: { editingTask = $0 }
        )
    }

    @ViewBuilder
    private var content: some View {
        let visible = viewModel?.visibleTasks ?? []
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Self.sectionSpacing) {
                if visible.isEmpty {
                    emptyState
                } else {
                    domainSection(.work, tasks: tasks(for: .work, from: visible))
                    domainSection(.personal, tasks: tasks(for: .personal, from: visible))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .refreshable { refreshViewModel() }
    }

    private var emptyState: some View {
        let accomplished = viewModel?.hasCompletedTasksToday == true

        return ContentUnavailableView {
            Label {
                Text(accomplished ? "You're all caught up." : "What's on your mind?")
            } icon: {
                Image(systemName: accomplished ? "checkmark.circle" : "note.text")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textTertiary)
            }
        } description: {
            Text(accomplished
                ? "You've completed everything you planned."
                : "Capture something you'd like to get done today.")
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .center)
    }

    @ViewBuilder
    private func domainSection(_ domain: TodayDomain, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(domain.title)
                    .font(AppFont.headlineSemibold)
                    .foregroundStyle(AppTheme.colors.textSecondary)
                Spacer(minLength: 0)
                addTaskButton(for: domain)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                if tasks.isEmpty {
                    Text("Nothing due today")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                } else {
                    taskRows(tasks)
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
    private func taskRows(_ rows: [TaskItem]) -> some View {
        ForEach(Array(rows.enumerated()), id: \.element.id) { index, task in
            TaskRowView(
                task: task,
                actions: rowActions,
                showsDueDate: viewModel?.isOverdue(task) == true,
                enablesFallbackSwipe: true
            )

            if index < rows.count - 1 {
                Divider()
                    .padding(.leading, 54)
            }
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
