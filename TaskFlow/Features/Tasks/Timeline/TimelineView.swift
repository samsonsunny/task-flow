import SwiftUI
import Combine
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
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \ReminderList.name) private var reminderLists: [ReminderList]

    let segment: ReminderSegment

    @State private var viewModel: ReminderSegmentViewModel?
    @State private var scheduleConfig: ScheduleConfig?
    @State private var newReminderConfig: NewReminderConfig?
    @State private var editingTask: TaskItem?
    @State private var activeCaptureDate: Date?
    @State private var quickCaptureText = ""
    @State private var skipNextDismiss = false
    @FocusState private var isQuickCaptureFocused: Bool

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            if segment == .today && !(viewModel?.overdueTasks.isEmpty ?? true) {
                Section {
                    if viewModel?.showOverdue ?? true {
                        ForEach(viewModel?.overdueTasks ?? []) { task in
                            taskListRow(task, showsDueDate: true)
                        }
                    }
                } header: {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel?.toggleShowOverdue()
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
                                .rotationEffect(.degrees((viewModel?.showOverdue ?? true) ? 0 : -90))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            if segment == .today || segment == .tomorrow {
                if let subtitle = segment.subtitle(now: viewModel?.now ?? Date()), !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if activeCaptureDate != nil && segment != .upcoming {
                quickCaptureRow
            }

            if let vm = viewModel {
                if segment == .upcoming {
                    upcomingContent(with: vm)
                } else if vm.filteredTasks.isEmpty && !segment.usesGroupedSections {
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
        .animation(.easeInOut, value: viewModel?.filteredTasks.count ?? 0)
        .overlay(alignment: .bottomTrailing) {
            ReminderFloatingAddButton {
                if segment == .upcoming {
                    newReminderConfig = NewReminderConfig(initialDate: nil, initialListID: nil, initialTitle: "")
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCaptureDate = Date()
                    }
                    isQuickCaptureFocused = true
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .onReceive(refreshTimer) { _ in
            viewModel?.refreshNow()
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
        .onChange(of: isQuickCaptureFocused) { _, focused in
            if !focused {
                DispatchQueue.main.async {
                    guard !skipNextDismiss else {
                        skipNextDismiss = false
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCaptureDate = nil
                        quickCaptureText = ""
                    }
                }
            }
        }
        .onAppear {
            viewModel = ReminderSegmentViewModel(modelContext: modelContext, segment: segment)
            viewModel?.update(tasks: tasks, lists: reminderLists, now: Date())
        }
        .onChange(of: tasks) { _, newTasks in
            viewModel?.update(tasks: newTasks, lists: reminderLists)
        }
        .onChange(of: reminderLists) { _, newLists in
            viewModel?.update(tasks: tasks, lists: newLists)
        }
        .onChange(of: editingTask) { _, task in
            if task == nil {
                viewModel?.update(tasks: tasks, lists: reminderLists)
            }
        }
    }

    private var quickCaptureRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.colors.primaryAction)
                    .frame(width: 20, height: 20)

                TextField("New Reminder", text: $quickCaptureText)
                    .font(.system(size: 17))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .focused($isQuickCaptureFocused)
                    .onSubmit(commitQuickCapture)
                    .submitLabel(.done)
                    .accessibilityIdentifier("quick-capture-field")

                Button {
                    openQuickCaptureEditor()
                } label: {
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.colors.textSecondary)
                }
                .accessibilityIdentifier("quick-capture-detail")
            }

            if let hintDate = viewModel?.captureDateHint(activeCaptureDate: activeCaptureDate) {
                Text("→ \(hintDate)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.colors.textTertiary)
                    .padding(.leading, 32)
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeCaptureDate = nil
                    quickCaptureText = ""
                }
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private func groupedContent(with vm: ReminderSegmentViewModel) -> some View {
        ForEach(vm.groupedSections) { section in
            Section {
                ForEach(section.tasks) { task in
                    taskListRow(task, showsDueDate: vm.shouldShowDueDate(for: segment))
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
        ForEach(vm.sortedFlatTasks) { task in
            taskListRow(task, showsDueDate: vm.shouldShowDueDate(for: segment))
                .transition(.scale.combined(with: .opacity))
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
                        Section {
                            ForEach(tasks) { task in
                                taskListRow(task, showsDueDate: false)
                            }

                            if activeCaptureDate == date {
                                quickCaptureRow
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
                        monthSectionView(title: title, date: date, dayGroups: dayGroups, isCollapsible: isCollapsible)
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
                isQuickCaptureFocused = true
            }
    }

    private func emptyDayRow(id: String, title: String, date: Date) -> some View {
        Section {
            if activeCaptureDate == date {
                quickCaptureRow
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
                    isQuickCaptureFocused = true
                }
        }
    }

    private func emptyMonthRow(title: String, date: Date) -> some View {
        Section {
            if activeCaptureDate == date {
                quickCaptureRow
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
                    isQuickCaptureFocused = true
                }
        }
    }

    private func addReminderButton(date: Date) -> some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                .foregroundStyle(AppTheme.colors.addReminderCircle)
                .frame(width: 20, height: 20)

            Text("Add Reminder")
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
            isQuickCaptureFocused = true
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .accessibilityIdentifier("upcoming-add-reminder-\(date)")
    }

    private func monthSectionView(title: String, date: Date, dayGroups: [TaskUIModel.DayInMonth], isCollapsible: Bool) -> some View {
        Section {
            if activeCaptureDate == date {
                quickCaptureRow
            }

            ForEach(dayGroups) { dayGroup in
                Section {
                    ForEach(dayGroup.tasks) { task in
                        taskListRow(task, showsDueDate: false)
                            .listRowInsets(EdgeInsets(top: 3, leading: 32, bottom: 3, trailing: 16))
                    }

                    if activeCaptureDate == dayGroup.date {
                        quickCaptureRow
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
                            isQuickCaptureFocused = true
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
                    isQuickCaptureFocused = true
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

    private func taskListRow(_ task: TaskItem, showsDueDate: Bool) -> some View {
        TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: { viewModel?.toggleCompletion(for: task) },
            onMoveToToday: (viewModel?.canMoveToToday(task) == true) ? { viewModel?.rescheduleToToday(task) } : nil,
            onMoveToTomorrow: (viewModel?.canMoveToTomorrow(task) == true) ? { viewModel?.rescheduleToTomorrow(task) } : nil,
            onMoveToLater: task.dueDate != nil ? { viewModel?.rescheduleToLater(task) } : nil,
            onSchedule: { presentScheduleSheet(for: task) },
            onMoveToList: { viewModel?.moveTask(task, to: $0) },
            availableLists: viewModel?.otherLists ?? [],
            onDelete: { viewModel?.delete(task: task) },
            onTap: { editingTask = task },
            showsDueDate: showsDueDate
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel?.delete(task: task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func commitQuickCapture() {
        let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        skipNextDismiss = true
        viewModel?.commitQuickCapture(text: text, captureDate: activeCaptureDate)
        quickCaptureText = ""
        isQuickCaptureFocused = true
    }

    private func openQuickCaptureEditor() {
        let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        let (initialDate, initialTitle) = viewModel?.openQuickCaptureEditor(text: text, captureDate: activeCaptureDate) ?? (nil, "")
        newReminderConfig = NewReminderConfig(
            initialDate: initialDate,
            initialListID: nil,
            initialTitle: initialTitle
        )
        quickCaptureText = ""
        activeCaptureDate = nil
    }

    private func presentScheduleSheet(for task: TaskItem) {
        scheduleConfig = ScheduleConfig(task: task)
    }
}
