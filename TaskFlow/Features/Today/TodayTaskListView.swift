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

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

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
                HStack(spacing: 24) {
                    ForEach(TodaySegment.allCases, id: \.self) { segment in
                        Button {
                            if selectedSegment != segment {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSegment = segment
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(segment.rawValue)
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(selectedSegment == segment ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                                Rectangle()
                                    .fill(selectedSegment == segment ? AppTheme.colors.tint : Color.clear)
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

                Button {
                    isCalendarPresented = true
                } label: {
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

                GeometryReader { geo in
                    let spacing: CGFloat = 8
                    let horizontalPadding: CGFloat = 20
                    let availableWidth = geo.size.width - (horizontalPadding * 2)
                    let maxCount = min(7, dateStripDays.count)
                    let chipWidth = max(48, (availableWidth - spacing * CGFloat(max(0, maxCount - 1))) / CGFloat(maxCount))
                    HStack(spacing: spacing) {
                        ForEach(Array(dateStripDays.prefix(maxCount)), id: \.self) { date in
                            dateChip(for: date, width: chipWidth)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 16)
                    .frame(width: geo.size.width, alignment: .leading)
                }
                .frame(height: 84)

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

    private func dateChip(for date: Date, width: CGFloat = 52) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayString = isToday ? "Today" : dayFormatter.string(from: date)
        let numString = dateFormatter.string(from: date)

        return Button {
            if selectedDate != calendar.startOfDay(for: date) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            selectedDate = calendar.startOfDay(for: date)
        } label: {
            VStack(spacing: 2) {
                Text(dayString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.colors.textOnTint : (isToday && !isSelected ? AppTheme.colors.tint : AppTheme.colors.textSecondary))
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(numString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? AppTheme.colors.textOnTint : AppTheme.colors.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: width, height: 68)
            .background(isSelected ? AppTheme.colors.tint : AppTheme.colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.colors.border.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                        showsGroupName: false,
                        groupNameOverride: nil
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

#Preview {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return TodayTaskListView()
        .modelContainer(container)
        .environment(AppState())
}
