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
    @AppStorage("today.selectedSegment") private var selectedSegmentRaw: String = TodaySegment.work.rawValue
    private var selectedSegment: TodaySegment {
        get { TodaySegment(rawValue: selectedSegmentRaw) ?? .work }
        set { selectedSegmentRaw = newValue.rawValue }
    }
    private let selectedFilter: TimeFilter = .upcoming
    @AppStorage("today.selectedDate") private var selectedDateTimestamp: Double = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    @State private var isCalendarPresented = false
    @State private var scrollRequestToken = 0
    @State private var lastHandledTodayResetID = 0
    @State private var hasPerformedInitialSetup = false

    private var selectedDate: Date {
        Date(timeIntervalSince1970: selectedDateTimestamp)
    }
    
    private var selectedDateBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: self.selectedDateTimestamp) },
            set: { self.selectedDateTimestamp = Calendar.current.startOfDay(for: $0).timeIntervalSince1970 }
        )
    }

    enum TodaySegment: String, CaseIterable {
        case work = "Work"
        case personal = "Personal"
    }

    enum TimeFilter: String, CaseIterable {
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

    private func hasIndicator(for segment: TodaySegment) -> Bool {
        let targetName = segment == .work ? AreaNames.work : AreaNames.personal
        var targetGroup: ReminderListGroup? = groups.first(where: { $0.name == targetName || ($0.name == "Home" && targetName == AreaNames.personal) })
        if targetGroup == nil {
            targetGroup = groups.first(where: { $0.isLocked && ((segment == .work && $0.name == AreaNames.work) || (segment == .personal && ($0.name == AreaNames.personal || $0.name == "Home"))) })
        }
        guard let group = targetGroup else { return false }
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        for task in allTasks {
            guard !(task.isCompleted ?? false) else { continue }
            guard task.reminderList?.group?.persistentModelID == group.persistentModelID else { continue }
            guard let dueDate = task.dueDate else { continue }
            if task.hasTime == true {
                if dueDate < now { return true }
                if calendar.isDate(dueDate, inSameDayAs: now) { return true }
            } else {
                let dueStart = calendar.startOfDay(for: dueDate)
                if dueStart < todayStart { return true }
                if dueStart == todayStart { return true }
            }
        }
        return false
    }

    private var hasOverdueTasks: Bool {
        !overdueTasks.isEmpty
    }

    private var contentHeaderTitle: String {
        Self.upcomingHeaderDateFormatter.string(from: selectedDate)
    }

    var body: some View {
        NavigationStack {
            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        TodaySegmentPicker(
                            selection: Binding(
                                get: { selectedSegment },
                                set: { selectedSegmentRaw = $0.rawValue }
                            ),
                            workHasIndicator: hasIndicator(for: .work),
                            personalHasIndicator: hasIndicator(for: .personal)
                        )

                        TaskListContentHeader(title: contentHeaderTitle, showsDisclosure: true) {
                            isCalendarPresented = true
                        }

                        WeekStripView(selectedDate: selectedDateBinding, scrollRequestToken: scrollRequestToken)
                            .padding(.bottom, 14)
                    }
                    .background(AppTheme.colors.pageBackground)
                }
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
                            initialDate: selectedDate,
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
            performInitialSetupIfNeeded()
            updateFilterForSegment()
            viewModel?.selectDate(selectedDate)
            refresh()
            handleTodayResetIfNeeded()
        }
        .onChange(of: appState.todayResetRequestID) { _, _ in
            handleTodayResetIfNeeded()
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

        .onChange(of: selectedDateTimestamp) { _, _ in
            viewModel?.selectDate(selectedDate)
            refresh()
        }
        .sheet(item: $newTaskConfig) { config in
            ReminderEditorView(initialDate: config.initialDate, initialListID: config.initialListID)
        }
        .sheet(isPresented: $isCalendarPresented) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: selectedDateBinding,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
            .onChange(of: selectedDateTimestamp) { _, _ in
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
        UpcomingAgendaView(
            sections: upcomingAgendaSections,
            selectedDate: selectedDateBinding,
            scrollRequestToken: scrollRequestToken,
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

    private func isOverdue(_ task: TaskItem) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        guard let dueDate = task.dueDate else { return false }
        if task.hasTime == true {
            return dueDate < now
        } else {
            return calendar.startOfDay(for: dueDate) < todayStart
        }
    }

    private var overdueTasks: [TaskItem] {
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        var result: [TaskItem] = []
        for task in allTasks {
            guard matchesArea(task) else { continue }
            guard !(task.isCompleted ?? false) else { continue }
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
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -10, to: today)!
        let days = (0..<41).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
        let daySet = Set(days)
        var tasksByDay: [Date: [TaskItem]] = [:]
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        for task in allTasks {
            guard matchesArea(task) else { continue }
            guard let dueDate = task.dueDate else { continue }
            let dueStart = calendar.startOfDay(for: dueDate)

            // Include in its due date section if it's in the range
            if daySet.contains(dueStart) {
                tasksByDay[dueStart, default: []].append(task)
            }

            // Also include overdue tasks in today section
            var isOverdueTask = false
            if task.hasTime == true {
                if dueDate < now && !(task.isCompleted ?? false) {
                    isOverdueTask = true
                }
            } else {
                if dueStart < todayStart && !(task.isCompleted ?? false) {
                    isOverdueTask = true
                }
            }
            if isOverdueTask {
                tasksByDay[todayStart, default: []].append(task)
            }
        }

        return days.map { day in
            let tasks = (tasksByDay[day] ?? [])
            // Remove duplicates within same day while preserving order preference
            var seen = Set<PersistentIdentifier>()
            let unique = tasks.filter { task in
                if seen.contains(task.persistentModelID) { return false }
                seen.insert(task.persistentModelID)
                return true
            }.sorted { lhs, rhs in
                let lhsDate = lhs.dueDate ?? .distantFuture
                let rhsDate = rhs.dueDate ?? .distantFuture
                if lhsDate != rhsDate { return lhsDate < rhsDate }
                let lhsCreated = lhs.createdAt ?? .distantPast
                let rhsCreated = rhs.createdAt ?? .distantPast
                if lhsCreated != rhsCreated { return lhsCreated < rhsCreated }
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }
            return UpcomingDaySection(date: day, tasks: unique)
        }
    }

    private func bootstrap() {
        if viewModel == nil {
            viewModel = TodayViewModel(modelContext: modelContext)
        }
        refresh()
    }

    private func performInitialSetupIfNeeded() {
        guard !hasPerformedInitialSetup else { return }
        hasPerformedInitialSetup = true
        let today = calendar.startOfDay(for: Date())
        guard selectedDateTimestamp != today.timeIntervalSince1970 else { return }
        selectedDateTimestamp = today.timeIntervalSince1970
        scrollRequestToken += 1
    }

    private func handleTodayResetIfNeeded() {
        guard appState.todayResetRequestID != lastHandledTodayResetID else { return }
        lastHandledTodayResetID = appState.todayResetRequestID
        let today = calendar.startOfDay(for: Date())
        selectedDateTimestamp = today.timeIntervalSince1970
        viewModel?.selectDate(today)
        refresh()
        scrollRequestToken += 1
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
