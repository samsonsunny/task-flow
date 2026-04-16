import SwiftUI
import SwiftData

struct TaskListGroupedScreenView: View {
    @Environment(\.modelContext) private var modelContext

    let tasks: [TaskItem]
    @Binding var captureTitle: String
    @Binding var captureDueSelection: CaptureDueSelection?
    @Binding var isCaptureDatePickerPresented: Bool
    @Binding var captureChosenDate: Date
    let captureFocused: FocusState<Bool>.Binding

    @State private var taskBeingScheduled: TaskItem?
    @State private var isTaskScheduleSheetPresented = false
    @State private var taskScheduleChosenDate = Calendar.current.startOfDay(for: Date())
    @State private var isOverdueExpanded = false
    @State private var isLaterExpanded = false

    var body: some View {
        List {
            TaskListHeaderView(
                title: "TaskFlow",
                subtitle: nil
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            ForEach(TaskListLogic.datedSections(from: tasks)) { section in
                Section {
                    if section.kind != .overdue || isOverdueExpanded {
                        ForEach(section.tasks) { task in
                            taskListRow(task, in: .dated(section.kind))
                        }
                    }
                } header: {
                    sectionHeader(
                        title: section.title,
                        subtitle: section.subtitle,
                        kind: .dated(section.kind),
                        isExpandable: section.kind == .overdue,
                        isExpanded: isOverdueExpanded,
                        onToggleExpanded: { isOverdueExpanded.toggle() }
                    )
                }
            }

            let laterTasks = tasks.filter { $0.dueDate == nil }
            Section {
                if isLaterExpanded {
                    ForEach(laterTasks) { task in
                        taskListRow(task, in: .later)
                    }
                }
            } header: {
                sectionHeader(
                    title: "Later",
                    subtitle: nil,
                    kind: .later,
                    isExpandable: true,
                    isExpanded: isLaterExpanded,
                    onToggleExpanded: { isLaterExpanded.toggle() }
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(AppTheme.colors.appBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { TaskCaptureBottomBarToolbar(title: $captureTitle, onSubmit: submitFromCapture, captureFocused: captureFocused) }
        .sheet(isPresented: $isTaskScheduleSheetPresented) {
            TaskScheduleDatePickerSheet(
                isPresented: $isTaskScheduleSheetPresented,
                chosenDate: $taskScheduleChosenDate,
                onChooseDate: { chosen in
                    taskBeingScheduled?.dueDate = chosen
                }
            )
        }
    }

    private func sectionHeader(
        title: String,
        subtitle: String?,
        kind: GroupKind,
        isExpandable: Bool = false,
        isExpanded: Bool = true,
        onToggleExpanded: (() -> Void)? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.colors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                }
            }

            Spacer()

            if isExpandable, let onToggleExpanded {
                Button {
                    onToggleExpanded()
                } label: {
                    Image(systemName: "chevron.\(isExpanded ? "down" : "right")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .padding(.leading, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .textCase(nil)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture { onTapSection(kind) }
    }

    private enum GroupKind: Hashable {
        case dated(TaskListLogic.DatedSection.Kind)
        case later
    }

    private func taskRow(_ task: TaskItem, in kind: GroupKind) -> some View {
        let calendar = Calendar.current
        let isLater = (kind == .later)
        let isToday: Bool = {
            guard case .dated(.day(let dayStart)) = kind else { return false }
            return calendar.isDateInToday(dayStart)
        }()
        let isTomorrow: Bool = {
            guard case .dated(.day(let dayStart)) = kind else { return false }
            return calendar.isDateInTomorrow(dayStart)
        }()
        let hasDueDate = task.dueDate != nil
        let showsDueDate: Bool = {
            switch kind {
            case .later:
                return false
            case .dated(let sectionKind):
                switch sectionKind {
                case .overdue:
                    return true
                case .day(let dayStart):
                    // For the next-5-days window we already show the day in the section header.
                    let todayStart = calendar.startOfDay(for: Date())
                    let windowEndExclusive = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? todayStart
                    return dayStart >= windowEndExclusive
                case .month, .future:
                    return true
                }
            }
        }()

        return TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: { toggleCompletion(for: task) },
            onMoveToToday: isToday ? nil : { rescheduleTaskToToday(task) },
            onMoveToTomorrow: isTomorrow ? nil : { rescheduleTaskToTomorrow(task) },
            onMoveToLater: (isLater || !hasDueDate) ? nil : { rescheduleTaskToLater(task) },
            onSchedule: { presentScheduleSheet(for: task) },
            showsDueDate: showsDueDate
        )
    }

    private func onTapSection(_ kind: GroupKind) {
        let calendar = Calendar.current
        switch kind {
        case .later:
            captureDueSelection = .someday
            captureFocused.wrappedValue = true
        case .dated(let sectionKind):
            switch sectionKind {
            case .overdue:
                captureDueSelection = .today
                captureFocused.wrappedValue = true
            case .day(let dayStart):
                if calendar.isDateInToday(dayStart) {
                    captureDueSelection = .today
                } else if calendar.isDateInTomorrow(dayStart) {
                    captureDueSelection = .tomorrow
                } else {
                    captureChosenDate = dayStart
                    captureDueSelection = .chooseDay(dayStart)
                }
                captureFocused.wrappedValue = true
            case .month(let monthStart):
                let normalizedMonthStart = calendar.startOfDay(for: monthStart)
                captureChosenDate = normalizedMonthStart
                captureDueSelection = .chooseDay(normalizedMonthStart)
                captureFocused.wrappedValue = true
            case .future:
                captureFocused.wrappedValue = true
            }
        }
    }

    private func taskListRow(_ task: TaskItem, in kind: GroupKind) -> some View {
        taskRow(task, in: kind)
            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    modelContext.delete(task)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    private func submitFromCapture() {
        let normalizedTitle = normalizedCaptureTitle(captureTitle)
        guard !normalizedTitle.isEmpty else { return }

        let task = TaskItem(taskTitle: normalizedTitle, dueDate: dueDateForCreate())
        modelContext.insert(task)
        captureTitle = ""
        captureDueSelection = nil
    }

    private func presentScheduleSheet(for task: TaskItem) {
        taskBeingScheduled = task
        taskScheduleChosenDate = Calendar.current.startOfDay(for: task.dueDate ?? Date())
        isTaskScheduleSheetPresented = true
    }

}

private extension TaskListGroupedScreenView {
    func normalizedCaptureTitle(_ rawTitle: String) -> String {
        let withSpacesForNewlines = rawTitle
            .components(separatedBy: .newlines)
            .joined(separator: " ")
        return withSpacesForNewlines.trimmingCharacters(in: .whitespacesAndNewlines)
}

    func effectiveCaptureDueSelection() -> CaptureDueSelection {
        captureDueSelection ?? .today
    }

    func dueDateForCreate() -> Date? {
        switch effectiveCaptureDueSelection() {
        case .today:
            return Date()
        case .tomorrow:
            return Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .someday:
            return nil
        case .chooseDay(let date):
            return Calendar.current.startOfDay(for: date)
        }
    }

    func toggleCompletion(for task: TaskItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            let next = !(task.isCompleted ?? false)
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
        }
    }

    func rescheduleTaskToToday(_ task: TaskItem) {
        task.dueDate = Calendar.current.startOfDay(for: Date())
    }

    func rescheduleTaskToTomorrow(_ task: TaskItem) {
        let calendar = Calendar.current
        let referenceDate = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) else {
            return
        }
        task.dueDate = tomorrow
    }

    func rescheduleTaskToLater(_ task: TaskItem) {
        task.dueDate = nil
    }
}
