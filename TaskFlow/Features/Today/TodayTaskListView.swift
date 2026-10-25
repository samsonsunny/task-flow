import SwiftUI
import SwiftData

extension Notification.Name {
    static let todayRefreshRequested = Notification.Name("todayRefreshRequested")
}

struct TodayTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]

    @State private var viewModel: TodayViewModel?
    @State private var editingTask: TaskItem?
    @State private var newTaskConfig: NewTaskSheetConfig?
    @AppStorage("today.selectedSegment") private var selectedSegment: TodaySegment = .work
    @State private var selectedFilter: TimeFilter = .today
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var isCalendarPresented = false

    enum TodaySegment: String, CaseIterable {
        case work = "Work"
        case personal = "Personal"
    }

    enum TimeFilter: String, CaseIterable {
        case today = "Today"
        case overdue = "Overdue"
        case upcoming = "Upcoming"
    }

    private var calendar: Calendar { Calendar.current }

    private static let contentHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return formatter
    }()

    private static let upcomingHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter
    }()

    private var hasOverdueTasks: Bool {
        !overdueTasks.isEmpty
    }

    private var contentHeaderTitle: String {
        switch selectedFilter {
        case .today:
            return Self.contentHeaderDateFormatter.string(from: calendar.startOfDay(for: Date()))
        case .overdue:
            return "Overdue tasks"
        case .upcoming:
            return Self.upcomingHeaderDateFormatter.string(from: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TodaySegmentPicker(selection: $selectedSegment)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(TimeFilter.allCases, id: \.self) { filter in
                            Button {
                                if selectedFilter != filter {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 18, weight: selectedFilter == filter ? .semibold : .regular))
                                    .foregroundStyle(selectedFilter == filter ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                                    .overlay(alignment: .topTrailing) {
                                        if filter == .overdue, hasOverdueTasks {
                                            Circle()
                                                .fill(AppTheme.colors.error)
                                                .frame(width: 6, height: 6)
                                                .offset(x: 8, y: -1)
                                                .accessibilityHidden(true)
                                        }
                                    }
                                    .frame(minHeight: 36)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .fixedSize()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                }

                if selectedFilter == .upcoming {
                    TaskListContentHeader(title: contentHeaderTitle, showsDisclosure: true) {
                        isCalendarPresented = true
                    }

                    WeekStripView(selectedDate: $selectedDate)
                        .padding(.bottom, 14)
                } else if selectedFilter == .today {
                    TaskListContentHeader(title: contentHeaderTitle)
                }

                content
            }
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
                        initialDate: selectedFilter == .upcoming || selectedFilter == .today ? selectedDate : nil,
                        initialListID: defaultListID
                    )
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
            viewModel?.selectDate(selectedDate)
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .todayRefreshRequested)) { _ in
            let today = calendar.startOfDay(for: Date())
            selectedDate = today
            viewModel?.selectDate(today)
            if selectedFilter == .today {
                refresh()
            }
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
            refresh()
        }
        .onChange(of: selectedFilter) { _, newValue in
            if newValue == .today {
                selectedDate = calendar.startOfDay(for: Date())
                viewModel?.selectDate(selectedDate)
            }
            refresh()
        }
        .onChange(of: selectedDate) { _, newValue in
            viewModel?.selectDate(newValue)
            if selectedFilter == .today || selectedFilter == .upcoming {
                refresh()
            }
        }
        .sheet(item: $newTaskConfig) { config in
            ReminderEditorView(initialDate: config.initialDate, initialListID: config.initialListID)
        }
        .sheet(isPresented: $isCalendarPresented) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .onChange(of: selectedDate) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    isCalendarPresented = false
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

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
        switch selectedFilter {
        case .today:
            let sections = viewModel?.sections ?? []
            if sections.isEmpty {
                ContentUnavailableView(
                    "No tasks",
                    systemImage: "sun.max",
                    description: Text("Tasks due on the selected date will appear here.")
                )
            } else {
                TodayTaskList(
                    tasks: sections.flatMap { $0.tasks },
                    onToggleCompletion: { viewModel?.toggleCompletion(for: $0) },
                    onDelete: { viewModel?.delete($0) },
                    onTap: { editingTask = $0 },
                    onRefresh: refresh
                )
            }
        case .overdue:
            let tasks = overdueTasks
            if tasks.isEmpty {
                ContentUnavailableView(
                    "No overdue tasks",
                    systemImage: "exclamationmark.circle",
                    description: Text("Tasks past their due date will appear here.")
                )
            } else {
                TodayTaskList(
                    tasks: tasks,
                    onToggleCompletion: { viewModel?.toggleCompletion(for: $0) },
                    onDelete: { viewModel?.delete($0) },
                    onTap: { editingTask = $0 },
                    onRefresh: refresh
                )
            }
        case .upcoming:
            UpcomingAgendaView(
                sections: upcomingAgendaSections,
                selectedDate: $selectedDate,
                onAddTask: { date in
                    newTaskConfig = NewTaskSheetConfig(
                        initialDate: date,
                        initialListID: defaultListID
                    )
                },
                onToggleCompletion: { viewModel?.toggleCompletion(for: $0) },
                onDelete: { viewModel?.delete($0) },
                onTapTask: { editingTask = $0 },
                onRefresh: refresh
            )
        }
    }

    private var targetGroupID: PersistentIdentifier? {
        let targetName = selectedSegment == .work ? AreaNames.work : AreaNames.personal
        if let group = groups.first(where: { $0.name == targetName || ($0.name == "Home" && targetName == AreaNames.personal) }) {
            return group.persistentModelID
        }
        if let group = groups.first(where: { $0.isLocked }) {
            let name = group.name
            if name == AreaNames.work && selectedSegment == .work { return group.persistentModelID }
            if (name == AreaNames.personal || name == "Home") && selectedSegment == .personal { return group.persistentModelID }
        }
        return nil
    }

    private func matchesArea(_ task: TaskItem) -> Bool {
        guard let targetGroupID else { return true }
        return task.reminderList?.group?.persistentModelID == targetGroupID
    }

    private var overdueTasks: [TaskItem] {
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        var result: [TaskItem] = []
        for task in allTasks {
            let isPendingUndo = viewModel?.pendingUndo?.id == task.persistentModelID
            guard task.isCompleted != true || isPendingUndo else { continue }
            guard matchesArea(task) else { continue }
            guard let dueDate = task.dueDate else { continue }
            if task.hasTime == true {
                if dueDate < now {
                    result.append(task)
                }
            } else {
                if calendar.startOfDay(for: dueDate) < todayStart {
                    result.append(task)
                }
            }
        }
        return result.sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }

    private var upcomingAgendaSections: [UpcomingDaySection] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else {
            return []
        }
        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
        let daySet = Set(days)
        var tasksByDay: [Date: [TaskItem]] = [:]

        for task in allTasks {
            let isPendingUndo = viewModel?.pendingUndo?.id == task.persistentModelID
            guard task.isCompleted != true || isPendingUndo else { continue }
            guard matchesArea(task) else { continue }
            guard let dueDate = task.dueDate else { continue }
            let dueStart = calendar.startOfDay(for: dueDate)
            guard daySet.contains(dueStart) else { continue }
            tasksByDay[dueStart, default: []].append(task)
        }

        return days.map { day in
            let tasks = (tasksByDay[day] ?? []).sorted { lhs, rhs in
                let lhsDate = lhs.dueDate ?? .distantFuture
                let rhsDate = rhs.dueDate ?? .distantFuture
                if lhsDate != rhsDate { return lhsDate < rhsDate }
                let lhsCreated = lhs.createdAt ?? .distantPast
                let rhsCreated = rhs.createdAt ?? .distantPast
                if lhsCreated != rhsCreated { return lhsCreated < rhsCreated }
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }
            return UpcomingDaySection(date: day, tasks: tasks)
        }
    }

    private func bootstrap() {
        if viewModel == nil {
            viewModel = TodayViewModel(modelContext: modelContext)
        }
        refresh()
    }

    private func refresh() {
        viewModel?.selectDate(selectedDate)
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
