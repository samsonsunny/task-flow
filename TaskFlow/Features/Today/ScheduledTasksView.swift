import SwiftUI
import SwiftData

struct ScheduledTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]

    @State private var displayedMonth = ScheduledTasksView.currentMonthStart()
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var dayTapToken = 0
    @State private var viewModel: TodayViewModel?
    @State private var editingTask: TaskItem?
    @State private var newTaskConfig: NewTaskSheetConfig?
    @State private var scheduleConfigTask: TaskItem?

    private let onShowToday: (() -> Void)?

    init(onShowToday: (() -> Void)? = nil) {
        self.onShowToday = onShowToday
    }

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                MonthCalendarView(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    taskDays: taskDays,
                    onDayTap: { _ in dayTapToken += 1 }
                )
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(AppTheme.colors.pageBackground)
            }
            .background(AppTheme.colors.pageBackground.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if let pending = viewModel?.pendingUndo {
                    UndoToast(title: pending.task.safeTitle) {
                        viewModel?.undoCompletion()
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel?.pendingUndo?.id)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Today") {
                        onShowToday?()
                    }
                    .accessibilityLabel("Show today's tasks")

                    Spacer()

                    Button {
                        newTaskConfig = NewTaskSheetConfig(
                            initialDate: newTaskDate,
                            initialListID: defaultListID
                        )
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Task")
                }
            }
            .navigationDestination(item: $editingTask) { task in
                ReminderEditorView(task: task, embedInNavigationStack: false)
            }
            .onAppear {
                let today = calendar.startOfDay(for: Date())
                selectedDate = today
                displayedMonth = ScheduledTasksView.currentMonthStart()
                dayTapToken += 1
                bootstrap()
                refresh()
            }
            .onChange(of: groups) { _, _ in refresh() }
            .onChange(of: allTasks) { _, _ in refresh() }
            .onChange(of: editingTask) { _, task in
                if task == nil { refresh() }
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

    private var content: some View {
        ScheduledTaskListView(
            sections: monthSections,
            selectedDate: $selectedDate,
            scrollRequestToken: dayTapToken,
            onToggleCompletion: { viewModel?.toggleCompletion(for: $0) },
            onDueDateAction: { task, action in
                if action == .custom {
                    scheduleConfigTask = task
                } else {
                    viewModel?.rescheduleTask(task, to: action)
                }
            },
            onDelete: { viewModel?.delete($0) },
            onTapTask: { editingTask = $0 },
            onRefresh: refresh
        )
    }

    private var defaultListID: ReminderList.ID? {
        lists.first(where: { $0.isBucket })?.persistentModelID ?? lists.first?.persistentModelID
    }

    private var newTaskDate: Date {
        if calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
            return selectedDate
        }
        let today = calendar.startOfDay(for: Date())
        if calendar.isDate(today, equalTo: displayedMonth, toGranularity: .month) {
            return today
        }
        return displayedMonth
    }

    private var taskDays: Set<Date> {
        var days = Set<Date>()
        for task in allTasks {
            guard let dueDate = task.dueDate else { continue }
            days.insert(calendar.startOfDay(for: dueDate))
        }
        return days
    }

    private var monthSections: [ScheduledDaySection] {
        var tasksByDay: [Date: [TaskItem]] = [:]

        for task in allTasks {
            guard let dueDate = task.dueDate else { continue }
            guard calendar.isDate(dueDate, equalTo: displayedMonth, toGranularity: .month) else { continue }
            let day = calendar.startOfDay(for: dueDate)
            tasksByDay[day, default: []].append(task)
        }

        return tasksByDay.keys.sorted().map { day in
            let tasks = (tasksByDay[day] ?? []).sorted { lhs, rhs in
                let lhsDate = lhs.dueDate ?? .distantFuture
                let rhsDate = rhs.dueDate ?? .distantFuture
                if lhsDate != rhsDate { return lhsDate < rhsDate }
                let lhsCreated = lhs.createdAt ?? .distantPast
                let rhsCreated = rhs.createdAt ?? .distantPast
                if lhsCreated != rhsCreated { return lhsCreated < rhsCreated }
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }
            return ScheduledDaySection(date: day, tasks: tasks)
        }
    }

    private static func currentMonthStart() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? calendar.startOfDay(for: Date())
    }

    private func bootstrap() {
        if viewModel == nil {
            viewModel = TodayViewModel(modelContext: modelContext)
        }
    }

    private func refresh() {
        viewModel?.selectFilter(.all)
        viewModel?.update(groups: groups, allTasks: allTasks, now: Date())
    }
}

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return NavigationStack {
        ScheduledTasksView()
    }
    .modelContainer(container)
}
