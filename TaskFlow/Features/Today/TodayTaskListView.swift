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
    @State private var selectedSegment: TodaySegment = .work
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var isCalendarPresented = false

    enum TodaySegment: String, CaseIterable {
        case work = "Work"
        case personal = "Personal"
    }

    private var calendar: Calendar { Calendar.current }

    private var dateStripDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        var days: [Date] = []
        // Past range
        if let pastStart = calendar.date(byAdding: .day, value: -365, to: today) {
            var current = pastStart
            while current <= today {
                days.append(current)
                if let next = calendar.date(byAdding: .day, value: 1, to: current) {
                    current = next
                } else {
                    break
                }
            }
        } else {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                days.append(yesterday)
            }
            days.append(today)
        }
        // Future range
        if let futureStart = calendar.date(byAdding: .day, value: 1, to: today) {
            var current = futureStart
            var count = 0
            while count < 730 {
                days.append(current)
                count += 1
                if let next = calendar.date(byAdding: .day, value: 1, to: current) {
                    current = next
                } else {
                    break
                }
            }
        }
        return days
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TodaySegmentPicker(selection: $selectedSegment)

                MonthYearButton(date: selectedDate) {
                    isCalendarPresented = true
                }

                DateStripView(days: dateStripDays, selectedDate: $selectedDate) {
                    selectedDate = calendar.startOfDay(for: Date())
                }
                .padding(.bottom, 8)

                if let pending = viewModel?.pendingUndo {
                    UndoToast(title: pending.task.safeTitle) {
                        viewModel?.undoCompletion()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                content
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
            updateFilterForSegment()
            viewModel?.selectDate(selectedDate)
            refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .todayRefreshRequested)) { _ in
            let today = calendar.startOfDay(for: Date())
            selectedDate = today
            viewModel?.selectDate(today)
            refresh()
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
        .onChange(of: selectedDate) { _, newValue in
            viewModel?.selectDate(newValue)
            refresh()
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
            TodayTaskList(
                tasks: sections.flatMap { $0.tasks },
                onToggleCompletion: { viewModel?.toggleCompletion(for: $0) },
                onDelete: { viewModel?.delete($0) },
                onTap: { editingTask = $0 },
                onRefresh: refresh
            )
        }
    }

    private var emptyTitle: String {
        "No tasks"
    }

    private var emptyDescription: String {
        "Tasks due on the selected date will appear here."
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
