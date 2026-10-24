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
        // yesterday, today, and upcoming (next 13 days for a clean strip)
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            days.append(yesterday)
        }
        days.append(today)
        for offset in stride(from: 1, to: 15, by: 1) {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                days.append(date)
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

                DateStripView(days: dateStripDays, selectedDate: $selectedDate)
                    .padding(.bottom, 12)

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
            viewModel?.selectDate(selectedDate)
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
                .navigationTitle("Calendar")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isCalendarPresented = false
                        }
                    }
                }
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
        if calendar.isDateInToday(selectedDate) {
            return "No \(selectedSegment.rawValue.lowercased()) tasks due today"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "No \(selectedSegment.rawValue.lowercased()) tasks on \(formatter.string(from: selectedDate))"
    }

    private var emptyDescription: String {
        if calendar.isDateInToday(selectedDate) {
            return "\(selectedSegment.rawValue) tasks due today or overdue will appear here."
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(selectedSegment.rawValue) tasks due on \(formatter.string(from: selectedDate)) or overdue will appear here."
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

private struct TodaySegmentPicker: View {
    @Binding var selection: TodayTaskListView.TodaySegment

    var body: some View {
        HStack(spacing: 24) {
            ForEach(TodayTaskListView.TodaySegment.allCases, id: \.self) { segment in
                Button {
                    if selection != segment {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = segment
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(segment.rawValue)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(selection == segment ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                        Rectangle()
                            .fill(selection == segment ? AppTheme.colors.tint : Color.clear)
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
                .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}

private struct MonthYearButton: View {
    let date: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(monthYearString)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

private struct DateStripView: View {
    let days: [Date]
    @Binding var selectedDate: Date

    @Environment(\.sizeCategory) private var sizeCategory

    private let calendar = Calendar.current

    private static let spacing: CGFloat = 8
    private static let horizontalPadding: CGFloat = 20
    private static let baseChipHeight: CGFloat = 64
    private static let verticalPadding: CGFloat = 8
    private static let targetCount = 5

    var body: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width - (Self.horizontalPadding * 2)
            let chipWidth = max(48, (availableWidth - Self.spacing * CGFloat(Self.targetCount - 1)) / CGFloat(Self.targetCount))
            let chipHeight = max(Self.baseChipHeight, Self.baseChipHeight + max(0, sizeCategory.scale - 1) * 12)
            HStack(spacing: Self.spacing) {
                ForEach(days, id: \.self) { date in
                    DateChip(
                        date: date,
                        width: chipWidth,
                        height: chipHeight,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                    ) {
                        select(date)
                    }
                }
            }
            .padding(.horizontal, Self.horizontalPadding)
            .frame(width: geo.size.width, alignment: .leading)
        }
        .frame(height: max(Self.baseChipHeight, Self.baseChipHeight + max(0, sizeCategory.scale - 1) * 12) + 16)
    }

    private func select(_ date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        if selectedDate != startOfDay {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        selectedDate = startOfDay
    }
}

private struct DateChip: View {
    let date: Date
    let width: CGFloat
    let height: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let isToday = calendar.isDateInToday(date)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayString = isToday ? "Today" : dayFormatter.string(from: date)
        let numString = dateFormatter.string(from: date)

        return Button(action: onSelect) {
            VStack(spacing: 0) {
                Text(dayString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.colors.textOnTint : AppTheme.colors.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 4) {
                    Text(numString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.colors.textOnTint : AppTheme.colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if isToday && !isSelected {
                        Circle()
                            .fill(AppTheme.colors.tint)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(width: width)
            .frame(minHeight: height)
            .background(isSelected ? AppTheme.colors.tint : AppTheme.colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct TodayTaskList: View {
    let tasks: [TaskItem]
    let onToggleCompletion: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void
    let onTap: (TaskItem) -> Void
    let onRefresh: () -> Void

    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRowView(
                    task: task,
                    isCompletedVisualState: task.isCompleted ?? false,
                    onToggleCompletion: { onToggleCompletion(task) },
                    onDelete: { onDelete(task) },
                    onTap: { onTap(task) },
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
        .refreshable { onRefresh() }
    }
}

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return TodayTaskListView()
        .modelContainer(container)
        .environment(AppState())
}
