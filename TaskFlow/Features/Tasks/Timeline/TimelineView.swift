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

struct ReminderSegmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \ReminderList.name) private var reminderLists: [ReminderList]

    let segment: ReminderSegment
    var isSelecting: Binding<Bool>? = nil

    @State private var viewModel: ReminderSegmentViewModel?
    @State private var scheduleConfig: ScheduleConfig?
    @State private var newReminderConfig: NewReminderConfig?
    @State private var editingTask: TaskItem?
    @State private var activeCaptureDate: Date?
    @State private var quickCaptureText = ""
    @State private var refreshTimer: Timer?
    @State private var showOverdue = false
    @State private var collapsedTasks: Set<PersistentIdentifier> = []
    @State private var defaultCollapsed = true
    @State private var selectedTasks: Set<PersistentIdentifier> = []
    @State private var savedCollapseState: Set<PersistentIdentifier> = []
    @State private var showDeleteConfirmation = false

    private var selecting: Bool {
        isSelecting?.wrappedValue ?? false
    }

    func enterSelectionMode() {
        savedCollapseState = collapsedTasks
        collapsedTasks = []
        selectedTasks = []
        isSelecting?.wrappedValue = true
        viewModel?.update(tasks: tasks, lists: reminderLists, now: Date(), collapsedTasks: collapsedTasks)
    }

    func exitSelectionMode() {
        isSelecting?.wrappedValue = false
        selectedTasks = []
        collapsedTasks = savedCollapseState
        viewModel?.update(tasks: tasks, lists: reminderLists, now: Date(), collapsedTasks: collapsedTasks)
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if segment == .today && !(viewModel?.overdueTasks.isEmpty ?? true) {
                Section {
                    if showOverdue {
                        let overdueNodes = (viewModel?.overdueTasks ?? []).map { task in
                            FlatTaskNode(id: task.persistentModelID, task: task, depth: 0, subtaskCount: 0)
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

                            Text("\(viewModel?.overdueTasks.count ?? 0) Overdue")
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
        .scrollContentBackground(.hidden)
        .background(AppTheme.colors.appBackground)
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded { /* tap dismiss handled by QuickCaptureRow internally */ }
        )
        .quickCaptureScroll(isActive: activeCaptureDate != nil, proxy: proxy)
    }
        .overlay(alignment: .bottomTrailing) {
            ReminderFloatingAddButton {
                if segment == .upcoming {
                    newReminderConfig = NewReminderConfig(initialDate: nil, initialListID: nil, initialTitle: "")
                } else {
                    activeCaptureDate = Date()
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
            .opacity(activeCaptureDate == nil && !selecting ? 1 : 0)
            .allowsHitTesting(activeCaptureDate == nil && !selecting)
            .animation(.easeInOut(duration: 0.15), value: activeCaptureDate == nil)
        }
        .overlay(alignment: .bottom) {
            if selecting {
                BulkActionsToolbar(
                    selectedCount: selectedTasks.count,
                    onDelete: { showDeleteConfirmation = true },
                    onRescheduleToday: { viewModel?.bulkRescheduleToToday(selectedTasks) },
                    onRescheduleTomorrow: { viewModel?.bulkRescheduleToTomorrow(selectedTasks) },
                    onRescheduleNextWeek: { viewModel?.bulkRescheduleToNextWeek(selectedTasks) },
                    onRescheduleLater: { viewModel?.bulkRescheduleToLater(selectedTasks) },
                    onRescheduleCustom: { /* custom date picker */ },
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
                onCommit: { dueDate, hasTime in
                    viewModel?.scheduleTask(config.task, dueDate: dueDate, hasTime: hasTime)
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
            if defaultCollapsed {
                let parentIDs = Set(tasks.compactMap { $0.parentTask?.persistentModelID })
                collapsedTasks = parentIDs
                defaultCollapsed = false
            }
            viewModel = ReminderSegmentViewModel(modelContext: modelContext, segment: segment)
            viewModel?.update(tasks: tasks, lists: reminderLists, now: Date(), collapsedTasks: collapsedTasks)
            scheduleMinuteAlignedTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        .onChange(of: tasks) { _, newTasks in
            viewModel?.update(tasks: newTasks, lists: reminderLists, now: Date(), collapsedTasks: collapsedTasks)
        }
        .onChange(of: reminderLists) { _, newLists in
            viewModel?.update(tasks: tasks, lists: newLists, now: Date(), collapsedTasks: collapsedTasks)
        }
        .onChange(of: editingTask) { _, task in
            if task == nil {
                viewModel?.update(tasks: tasks, lists: reminderLists, now: Date(), collapsedTasks: collapsedTasks)
            }
        }
        .onChange(of: appState.mutationCount) { _, _ in
            viewModel?.update(tasks: tasks, lists: reminderLists, now: Date(), collapsedTasks: collapsedTasks)
        }
    }

    @ViewBuilder
    private func groupedContent(with vm: ReminderSegmentViewModel) -> some View {
        ForEach(vm.groupedSections) { section in
            Section {
                ForEach(section.tasks) { task in
                    let node = FlatTaskNode(id: task.persistentModelID, task: task, depth: 0, subtaskCount: 0)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
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

            if activeCaptureDate != nil && !selecting {
                QuickCaptureRow(
                    text: $quickCaptureText,
                    onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: activeCaptureDate) },
                    onDismiss: { activeCaptureDate = nil }
                )
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
                case .categoryHeader(_, let title):
                    categoryHeaderRow(title: title)

                case .daySection(let id, let date, let title, let tasks, let isInHorizon):
                    if tasks.isEmpty {
                        emptyDayRow(id: id, title: title, date: date)
                    } else {
                        let sectionNodes = viewModel?.flatNodes(for: tasks, collapsedTasks: collapsedTasks) ?? []
                        Section {
                            ForEach(sectionNodes) { node in
                                taskListRow(node, showsDueDate: false)
                            }

                            if activeCaptureDate == date {
                                QuickCaptureRow(
                                    text: $quickCaptureText,
                                    onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: date) },
                                    onDismiss: { activeCaptureDate = nil }
                                )
                            } else {
                                addReminderButton(date: date)
                            }
                        } header: {
                            dayHeader(title: title, date: date, isInHorizon: isInHorizon)
                        }
                    }

                case .monthSection(_, let date, let title, let dayGroups, let isCollapsible):
                    if dayGroups.isEmpty {
                        emptyMonthRow(title: title, date: date)
                    } else {
                        monthSectionView(title: title, date: date, dayGroups: dayGroups, isCollapsible: isCollapsible, vm: vm)
                    }
                }
            }
        }
    }

    private func categoryHeaderRow(title: String) -> some View {
        Section {
            EmptyView()
                .listRowSeparator(.hidden)
        } header: {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
                .textCase(nil)
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeCaptureDate = date
                }
            }
    }

    private func emptyDayRow(id: String, title: String, date: Date) -> some View {
        Section {
            if activeCaptureDate == date {
                QuickCaptureRow(
                    text: $quickCaptureText,
                    onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: date) },
                    onDismiss: { activeCaptureDate = nil }
                )
            }

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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCaptureDate = date
                    }
                }
        }
    }

    private func emptyMonthRow(title: String, date: Date) -> some View {
        Section {
            if activeCaptureDate == date {
                QuickCaptureRow(
                    text: $quickCaptureText,
                    onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: date) },
                    onDismiss: { activeCaptureDate = nil }
                )
            }

            EmptyView()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        } header: {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textTertiary)
                .textCase(nil)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCaptureDate = date
                    }
                }
        }
    }

    private func addReminderButton(date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 20, height: 20)

            Text("New Reminder")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.colors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                activeCaptureDate = date
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .accessibilityIdentifier("upcoming-add-reminder-\(date)")
    }

    private func monthSectionView(title: String, date: Date, dayGroups: [TaskUIModel.DayInMonth], isCollapsible: Bool, vm: ReminderSegmentViewModel) -> some View {
        Section {
            if activeCaptureDate == date {
                QuickCaptureRow(
                    text: $quickCaptureText,
                    onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: date) },
                    onDismiss: { activeCaptureDate = nil }
                )
            }

            ForEach(dayGroups) { dayGroup in
                let dayNodes = vm.flatNodes(for: dayGroup.tasks, collapsedTasks: collapsedTasks)
                Section {
                    ForEach(dayNodes) { node in
                        taskListRow(node, showsDueDate: false)
                            .listRowInsets(EdgeInsets(top: 3, leading: 32, bottom: 3, trailing: 16))
                    }

                    if activeCaptureDate == dayGroup.date {
                        QuickCaptureRow(
                            text: $quickCaptureText,
                            onSubmit: { viewModel?.commitQuickCapture(text: $0, captureDate: dayGroup.date) },
                            onDismiss: { activeCaptureDate = nil }
                        )
                    } else if !dayGroup.tasks.isEmpty {
                        addReminderButton(date: dayGroup.date)
                            .listRowInsets(EdgeInsets(top: 0, leading: 32, bottom: 0, trailing: 16))
                    }
                } header: {
                    Text(dayGroup.title)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .textCase(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeCaptureDate = dayGroup.date
                            }
                        }
                        .listRowBackground(Color.clear)
                }
            }
        } header: {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
                .textCase(nil)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCaptureDate = date
                    }
                }
        }
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
        .padding(.horizontal, 16)
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
            onMoveToToday: (viewModel?.canMoveToToday(task) == true) ? { viewModel?.rescheduleToToday(task) } : nil,
            onMoveToTomorrow: (viewModel?.canMoveToTomorrow(task) == true) ? { viewModel?.rescheduleToTomorrow(task) } : nil,
            onMoveToNextWeek: (viewModel?.canMoveToNextWeek(task) == true) ? { viewModel?.rescheduleToNextWeek(task) } : nil,
            onMoveToLater: task.dueDate != nil ? { viewModel?.rescheduleToLater(task) } : nil,
            onSchedule: { presentScheduleSheet(for: task) },
            onMoveToList: { viewModel?.moveTask(task, to: $0) },
            listSections: viewModel?.listSections ?? [],
            onDelete: { viewModel?.delete(task: task) },
            onSwipeNextDay: (segment == .today || segment == .tomorrow) ? { viewModel?.rescheduleToNextDay(task) } : nil,
            onTap: {
                activeCaptureDate = nil
                quickCaptureText = ""
                editingTask = task
            },
            showsDueDate: showsDueDate,
            nestingDepth: node.depth,
            subtaskCount: node.subtaskCount,
            isCollapsed: collapsedTasks.contains(task.persistentModelID),
            onToggleCollapse: node.subtaskCount > 0 ? {
                if collapsedTasks.contains(task.persistentModelID) {
                    collapsedTasks.remove(task.persistentModelID)
                } else {
                    collapsedTasks.insert(task.persistentModelID)
                }
                viewModel?.update(tasks: tasks, lists: reminderLists, now: Date(), collapsedTasks: collapsedTasks)
            } : nil,
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
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
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
