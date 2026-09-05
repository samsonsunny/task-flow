import SwiftUI
import SwiftData

private struct NewReminderConfig: Identifiable {
    let id = UUID()
    let initialDate: Date?
    let initialListID: ReminderList.ID?
    let initialTitle: String
}

private struct ScheduleConfig: Identifiable {
    let id = UUID()
    let task: TaskItem
}

private struct BulkScheduleConfig: Identifiable {
    let id = UUID()
    let taskIDs: Set<PersistentIdentifier>
}

struct ReminderSegmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \ReminderList.name) private var reminderLists: [ReminderList]

    let segment: ReminderSegment
    var isSelecting: Binding<Bool>? = nil
    var headerAccessory: (() -> AnyView)? = nil

    @State private var viewModel: ReminderSegmentViewModel?
    @State private var scheduleConfig: ScheduleConfig?
    @State private var bulkScheduleConfig: BulkScheduleConfig?
    @State private var newReminderConfig: NewReminderConfig?
    @State private var editingTask: TaskItem?
    @State private var refreshTimer: Timer?
    @State private var showOverdue = false
    @State private var selectedTasks: Set<PersistentIdentifier> = []
    @State private var showDeleteConfirmation = false

    private var selecting: Bool {
        isSelecting?.wrappedValue ?? false
    }

    func enterSelectionMode() {
        selectedTasks = []
        isSelecting?.wrappedValue = true
        viewModel?.update(tasks: tasks, lists: reminderLists, now: Date())
    }

    func exitSelectionMode() {
        isSelecting?.wrappedValue = false
        selectedTasks = []
        viewModel?.update(tasks: tasks, lists: reminderLists, now: Date())
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if let headerAccessory = headerAccessory {
                    headerAccessory()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                if segment == .today && !(viewModel?.overdueDisplayTasks.isEmpty ?? true) {
                Section {
                    if showOverdue {
                        let overdueNodes = (viewModel?.overdueDisplayTasks ?? []).map { task in
                            FlatTaskNode(id: task.taskId ?? "", task: task, depth: 0, subtaskSummary: task.subtaskSummary)
                        }
                        ForEach(overdueNodes) { node in
                            taskListRow(node, showsDueDate: true)
                        }
                    }
                } header: {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOverdue.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(AppTheme.colors.error)
                                .font(.caption)

                            Text("\(viewModel?.overdueDisplayTasks.count ?? 0) Overdue")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.colors.error)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.colors.textTertiary)
                                .rotationEffect(.degrees(showOverdue ? 0 : -90))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            if let vm = viewModel {
                if segment == .upcoming {
                    upcomingContent(with: vm)
                } else if segment == .today || segment == .tomorrow {
                    todayLikeContent(with: vm)
                } else if vm.flatNodes.isEmpty && !segment.usesGroupedSections {
                    emptyState
                } else if segment.usesGroupedSections {
                    groupedContent(with: vm)
                } else {
                    flatContent(with: vm)
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(0)
        .listRowSpacing(0)
        .contentMargins(.top, 0, for: .scrollContent)
        .contentMargins(.bottom, 72, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }
        .overlay(alignment: .bottom) {
            if selecting {
                BulkActionsToolbar(
                    selectedCount: selectedTasks.count,
                    onDelete: { showDeleteConfirmation = true },
                    onRescheduleToday: { viewModel?.bulkRescheduleToToday(selectedTasks) },
                    onRescheduleTomorrow: { viewModel?.bulkRescheduleToTomorrow(selectedTasks) },
                    onRescheduleThisWeekend: { viewModel?.bulkRescheduleToThisWeekend(selectedTasks) },
                    onRescheduleNextWeek: { viewModel?.bulkRescheduleToNextWeek(selectedTasks) },
                    onRescheduleCustom: { bulkScheduleConfig = BulkScheduleConfig(taskIDs: selectedTasks) },
                    onRescheduleNone: { viewModel?.bulkRescheduleToNone(selectedTasks) },
                    onMoveToList: { viewModel?.bulkMoveToList(selectedTasks, list: $0) },
                    listSections: viewModel?.listSections ?? [],
                    onSetPriority: { viewModel?.bulkSetPriority(selectedTasks, priority: $0) },
                    onComplete: { bulkToggleCompletion() },
                    onDone: { exitSelectionMode() }
                )
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.25), value: selecting)
            }
        }
        .sheet(item: $scheduleConfig) { config in
            TaskScheduleDatePickerSheet(
                isPresented: Binding(
                    get: { scheduleConfig != nil },
                    set: { if !$0 { scheduleConfig = nil } }
                ),
                initialDueDate: config.task.dueDate,
                initialFocus: config.task.dueDate == nil ? .date : .time,
                onCommit: { dueDate, hasTime in
                    viewModel?.scheduleTask(config.task, dueDate: dueDate, hasTime: hasTime)
                }
            )
        }
        .sheet(item: $bulkScheduleConfig) { config in
            TaskScheduleDatePickerSheet(
                isPresented: Binding(
                    get: { bulkScheduleConfig != nil },
                    set: { if !$0 { bulkScheduleConfig = nil } }
                ),
                initialDueDate: nil,
                initialFocus: .date,
                onCommit: { dueDate, hasTime in
                    viewModel?.bulkRescheduleToDate(config.taskIDs, dueDate: dueDate, hasTime: hasTime)
                }
            )
        }
        .sheet(item: $newReminderConfig) { config in
            ReminderEditorView(initialDate: config.initialDate, initialListID: config.initialListID, initialTitle: config.initialTitle)
        }
        .sheet(item: $editingTask) { task in
            ReminderEditorView(task: task)
        }
        .alert("Delete \(selectedTasks.count) task\(selectedTasks.count == 1 ? "" : "s")?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                bulkDelete()
            }
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear {
            viewModel = ReminderSegmentViewModel(modelContext: modelContext, segment: segment)
            viewModel?.update(tasks: tasks, lists: reminderLists, now: Date())
            scheduleMinuteAlignedTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        .onChange(of: tasks) { _, newTasks in
            viewModel?.update(tasks: newTasks, lists: reminderLists, now: Date())
        }
        .onChange(of: reminderLists) { _, newLists in
            viewModel?.update(tasks: tasks, lists: newLists, now: Date())
        }
        .onChange(of: editingTask) { _, task in
            if task == nil {
                viewModel?.update(tasks: tasks, lists: reminderLists, now: Date())
            }
        }
        .onChange(of: appState.mutationCount) { _, _ in
            viewModel?.update(tasks: tasks, lists: reminderLists, now: Date())
        }
    }

    @ViewBuilder
    private func groupedContent(with vm: ReminderSegmentViewModel) -> some View {
        ForEach(vm.groupedSections) { section in
            Section {
                ForEach(section.tasks) { task in
                    let node = FlatTaskNode(id: task.taskId ?? "", task: task, depth: 0, subtaskSummary: task.subtaskSummary)
                    taskListRow(node, showsDueDate: vm.shouldShowDueDate(for: segment))
                }
            } header: {
                sectionHeader(
                    title: section.title,
                    subtitle: section.subtitle,
                    kind: section.kind
                )
            }
        }
    }

    @ViewBuilder
    private func flatContent(with vm: ReminderSegmentViewModel) -> some View {
        ForEach(vm.flatNodes) { node in
            taskListRow(node, showsDueDate: vm.shouldShowDueDate(for: segment))
                .transition(.scale.combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func reorderableFlatContent(with vm: ReminderSegmentViewModel) -> some View {
        ForEach(vm.rootedNodes, id: \.root.id) { group in
            taskListRow(group.root, showsDueDate: vm.shouldShowDueDate(for: segment))
                .transition(.scale.combined(with: .opacity))
            ForEach(group.children) { child in
                taskListRow(child, showsDueDate: vm.shouldShowDueDate(for: segment))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onMove { fromOffsets, toOffset in
            guard !selecting else { return }
            let rootTasks = vm.rootedNodes.map(\.root.task)
            print("[REORDER] >>> onMove fired | segment=\(segment.rawValue) fromIndices=\(fromOffsets.sorted()) toOffset=\(toOffset)")
            print("[REORDER] >>> visible rows (flatNodes): \(vm.flatNodes.map { "\($0.task.safeTitle)(d\($0.depth))" })")
            print("[REORDER] >>> rootedNodes.count=\(vm.rootedNodes.count) groups=\(vm.rootedNodes.map { "\($0.root.task.safeTitle)+\($0.children.count)" })")
            print("[REORDER] >>> rootTasks passed to moveTasks: \(rootTasks.map(\.safeTitle))")
            viewModel?.moveTasks(fromOffsets: fromOffsets, toOffset: toOffset, in: rootTasks)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(segment.emptyTitle)
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textSecondary)

            Text(segment.emptyMessage)
                .font(.caption)
                .foregroundStyle(AppTheme.colors.textTertiary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }

    private func todayLikeContent(with vm: ReminderSegmentViewModel) -> some View {
        Section {
            if vm.flatNodes.isEmpty {
                emptyState
            } else {
                reorderableFlatContent(with: vm)
            }
        } header: {
            if let subtitle = segment.subtitle(now: vm.now), !subtitle.isEmpty {
                Text(subtitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .textCase(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
            }
        }
    }

    @ViewBuilder
    private func upcomingContent(with vm: ReminderSegmentViewModel) -> some View {
        let groups = vm.upcomingGroups

        if !groups.isEmpty {
            ForEach(groups) { group in
                switch group {
                case .monthHeader(_, let date, let title):
                    monthHeaderRow(title: title, date: date)

                case .monthSection(_, let date, let title, let dayGroups, _):
                    if dayGroups.isEmpty {
                        emptyMonthRow(title: title, date: date)
                    } else {
                        monthSectionView(title: title, date: date, dayGroups: dayGroups, vm: viewModel)
                    }

                case .daySection(_, let date, let title, let tasks, let isInHorizon):
                    if tasks.isEmpty {
                        emptyDayRow(title: title, date: date)
                    } else {
                        let sectionNodes = viewModel?.flatNodes(for: tasks) ?? []
                        Section {
                            ForEach(sectionNodes) { node in
                                taskListRow(node, showsDueDate: false)
                            }
                        } header: {
                            dayHeader(title: title, date: date, isInHorizon: isInHorizon)
                        }
                    }
                }
            }
        }
    }

    private func monthHeaderRow(title: String, date: Date) -> some View {
        Section {
            EmptyView()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } header: {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.colors.textPrimary)
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.bottom, 4)
        }
    }

    private func dayHeader(title: String, date: Date, isInHorizon: Bool) -> some View {
        Text(title)
            .font(isInHorizon ? .headline : .subheadline)
            .foregroundStyle(AppTheme.colors.textPrimary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                startCapture(for: date)
            }
    }

    private func emptyDayRow(title: String, date: Date) -> some View {
        Section {
            EmptyView()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } header: {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textTertiary)
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    startCapture(for: date)
                }
        }
    }

    private func emptyMonthRow(title: String, date: Date) -> some View {
        Section {
            EmptyView()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } header: {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textTertiary)
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    startCapture(for: date)
                }
        }
    }

    private func monthSectionView(title: String, date: Date, dayGroups: [TaskUIModel.DayInMonth], vm: ReminderSegmentViewModel?) -> some View {
        Section {
            ForEach(dayGroups) { dayGroup in
                let dayNodes = vm?.flatNodes(for: dayGroup.tasks) ?? []
                Section {
                    ForEach(dayNodes) { node in
                        taskListRow(node, showsDueDate: false)
                    }
                } header: {
                    Text(dayGroup.title)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .textCase(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startCapture(for: dayGroup.date)
                        }
                }
            }
        } header: {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.colors.textPrimary)
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    startCapture(for: date)
                }
        }
    }

    private func startCapture(for date: Date) {
        appState.pendingCaptureDate = date
    }

    private func sectionHeader(title: String, subtitle: String?, kind: TaskUIModel.DatedSection.Kind?) -> some View {
        let isMonth: Bool
        let date: Date?
        switch kind {
        case .day(let d):
            isMonth = false
            date = d
        case .month:
            isMonth = true
            date = nil
        default:
            isMonth = false
            date = nil
        }

        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(isMonth ? .headline : .subheadline)
                .foregroundStyle(isMonth ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }
        }
        .textCase(nil)
        .padding(.top, isMonth ? 16 : 8)
        .padding(.bottom, isMonth ? 4 : 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if let date = date {
                newReminderConfig = NewReminderConfig(initialDate: date, initialListID: nil, initialTitle: "")
            }
        }
    }

    private func taskListRow(_ node: FlatTaskNode, showsDueDate: Bool) -> some View {
        let task = node.task
        return TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: { viewModel?.toggleCompletion(for: task) },
            onDueDateAction: { action in
                switch action {
                case .none:
                    viewModel?.rescheduleToNone(task)
                case .today:
                    viewModel?.rescheduleToToday(task)
                case .tomorrow:
                    viewModel?.rescheduleToTomorrow(task)
                case .thisWeekend:
                    viewModel?.rescheduleToThisWeekend(task)
                case .nextWeek:
                    viewModel?.rescheduleToNextWeek(task)
                case .custom:
                    presentScheduleSheet(for: task)
                }
            },
            onMoveToList: { viewModel?.moveTask(task, to: $0) },
            listSections: viewModel?.listSections ?? [],
            excludedListID: task.reminderList?.persistentModelID,
            onDelete: { viewModel?.delete(task: task) },
            onSwipeNextDay: (segment == .today || segment == .tomorrow) ? { viewModel?.rescheduleToNextDay(task) } : nil,
            onTap: {
                editingTask = task
            },
            showsDueDate: showsDueDate,
            subtaskSummary: node.subtaskSummary,
            isSelecting: selecting,
            isSelected: selectedTasks.contains(task.persistentModelID),
            onSelectToggle: {
                if selectedTasks.contains(task.persistentModelID) {
                    selectedTasks.remove(task.persistentModelID)
                } else {
                    selectedTasks.insert(task.persistentModelID)
                }
            }
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func presentScheduleSheet(for task: TaskItem) {
        scheduleConfig = ScheduleConfig(task: task)
    }

    private func scheduleMinuteAlignedTimer() {
        refreshTimer?.invalidate()
        let interval: TimeInterval = 60
        let now = Date().timeIntervalSinceReferenceDate
        let nextMinute = ceil(now / interval) * interval
        let delay = nextMinute - now

        let timer = Timer(
            fire: Date().addingTimeInterval(delay),
            interval: interval,
            repeats: true
        ) { [weak viewModel] _ in
            Task { @MainActor in
                viewModel?.refreshNow()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func bulkDelete() {
        for id in selectedTasks {
            if let task = tasks.first(where: { $0.persistentModelID == id }) {
                viewModel?.delete(task: task)
            }
        }
        exitSelectionMode()
    }

    private func bulkToggleCompletion() {
        for id in selectedTasks {
            if let task = tasks.first(where: { $0.persistentModelID == id }) {
                viewModel?.toggleCompletion(for: task)
            }
        }
    }
}
