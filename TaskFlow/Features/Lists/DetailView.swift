import SwiftUI
import Combine
import UniformTypeIdentifiers
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

private struct TaskDropDelegate: DropDelegate {
    let targetTask: TaskItem
    let performDrop: (TaskItem, CGPoint) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        performDrop(targetTask, info.location)
        return true
    }
}

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    let listID: ReminderList.ID

    @Query(sort: \TaskItem.sortOrder, order: .forward) private var allTasks: [TaskItem]
    @Query(sort: \ReminderList.createdAt) private var allLists: [ReminderList]

    @State private var viewModel: ListDetailViewModel?
    @State private var scheduleConfig: ScheduleConfig?
    @State private var bulkScheduleConfig: BulkScheduleConfig?
    @State private var newReminderConfig: NewReminderConfig?
    @State private var editingTask: TaskItem?
    @State private var quickCaptureText = ""
    @State private var isSelecting = false
    @State private var selectedTasks: Set<PersistentIdentifier> = []
    @State private var showDeleteConfirmation = false
    @State private var showScrollToBottom = false
    @FocusState private var quickCaptureFocused: Bool

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let newTaskScrollDuration: Double = 1.4

    private var isBarIdle: Bool {
        !quickCaptureFocused && quickCaptureText.isEmpty
    }

    private var hasValidCaptureContent: Bool {
        !quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func enterSelectionMode() {
        selectedTasks = []
        isSelecting = true
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
        viewModel?.update(tasks: listTasks, lists: allLists, allTasks: allTasks, now: Date())
    }

    private func exitSelectionMode() {
        isSelecting = false
        selectedTasks = []
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
        viewModel?.update(tasks: listTasks, lists: allLists, allTasks: allTasks, now: Date())
    }

    var body: some View {
        ScrollViewReader { proxy in
            detailList(proxy: proxy)
        }
    }

    private func detailList(proxy: ScrollViewProxy) -> some View {
        baseList(proxy: proxy)
            .onChange(of: viewModel?.lastAddedTaskID) { _, id in
                guard id != nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    var transaction = Transaction(animation: .easeInOut(duration: newTaskScrollDuration))
                    transaction.disablesAnimations = false
                    withTransaction(transaction) {
                        proxy.scrollTo("list-detail-scroll-bottom", anchor: .bottom)
                    }
                }
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
                viewModel = ListDetailViewModel(modelContext: modelContext, listID: listID)
                let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
                viewModel?.update(tasks: listTasks, lists: allLists, allTasks: allTasks, now: Date())
            }
            .onChange(of: allTasks) { _, newTasks in
                let listTasks = newTasks.filter { $0.reminderList?.persistentModelID == listID }
                viewModel?.update(tasks: listTasks, lists: allLists, allTasks: newTasks)
            }
            .onChange(of: allLists) { _, newLists in
                let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
                viewModel?.update(tasks: listTasks, lists: newLists, allTasks: allTasks)
            }
    }

    private func baseList(proxy: ScrollViewProxy) -> some View {
        scrolledList(proxy: proxy)
            .navigationTitle(viewModel?.list?.name ?? "")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                topBarToolbar
            }
            .overlay(alignment: .bottom) {
                if isSelecting {
                    bulkActionsOverlay
                } else {
                    bottomBar(proxy: proxy)
                }
            }
    }

    private func scrolledList(proxy: ScrollViewProxy) -> some View {
        listContent
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.colors.secondaryBackground)
            .scrollDismissesKeyboard(.interactively)
            .onScrollGeometryChange(
                for: ScrollGeometry.self,
                of: { $0 },
                action: { _, geometry in
                    updateScrollState(geometry)
                }
            )
            .simultaneousGesture(
                TapGesture().onEnded {
                    if quickCaptureFocused {
                        quickCaptureFocused = false
                    }
                }
            )
    }

    private var listContent: some View {
        List {
            if let vm = viewModel {
                if vm.flatNodes.isEmpty {
                    emptyState
                } else {
                    ForEach(vm.flatNodes) { node in
                        taskListRow(node)
                            .id(node.id)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .onMove { fromOffsets, toOffset in
                        let taskFromOffsets = IndexSet(fromOffsets.map { flatToTaskIndex($0) })
                        let taskToOffset = flatToTaskIndex(toOffset)
                        vm.moveTasks(fromOffsets: taskFromOffsets, toOffset: taskToOffset)
                    }

                    Color.clear
                        .frame(height: 110)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .id("list-detail-scroll-bottom")
                }
            }
        }
    }

    private func updateScrollState(_ geometry: ScrollGeometry) {
        let threshold: CGFloat = 48
        let overflows = geometry.contentSize.height > geometry.containerSize.height + 1
        let isNearBottom = geometry.contentOffset.y + geometry.containerSize.height >= geometry.contentSize.height - threshold
        showScrollToBottom = overflows && !isNearBottom
    }

    private func bottomBar(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            if showScrollToBottom {
                scrollToBottomButton(proxy: proxy)
            }
            quickCaptureBar
        }
    }

    @ToolbarContentBuilder
    private var topBarToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if isSelecting {
                Button("Done") {
                    exitSelectionMode()
                }
            } else {
                Menu {
                    Button("Select Items") {
                        enterSelectionMode()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }

    private var bulkActionsOverlay: some View {
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
        .animation(.easeInOut(duration: 0.25), value: isSelecting)
    }

    private func scrollToBottomButton(proxy: ScrollViewProxy) -> some View {
        Button {
            scrollToBottom(proxy: proxy)
        } label: {
            GlassEffectContainer {
                Image(systemName: "arrow.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.primaryAction)
                    .frame(width: 34, height: 34)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
            }
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .padding(.bottom, 10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.15), value: showScrollToBottom)
        .accessibilityIdentifier("list-detail-scroll-bottom-button")
        .accessibilityLabel("Scroll to bottom")
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        var transaction = Transaction(animation: .easeInOut(duration: newTaskScrollDuration))
        transaction.disablesAnimations = false
        withTransaction(transaction) {
            proxy.scrollTo("list-detail-scroll-bottom", anchor: .bottom)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No tasks")
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Add a task below to get started.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }

    private var quickCaptureBar: some View {
        HStack(spacing: 10) {
            if isBarIdle {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.primaryAction)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("list-bar-plus")
            }

            ZStack(alignment: .topLeading) {
                TextField("", text: $quickCaptureText, axis: .vertical)
.focused($quickCaptureFocused)
                        .lineLimit(1...5)
                        .frame(minHeight: 28, alignment: .center)
                        .submitLabel(.return)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("list-bar-field")
                        .onSubmit { commitQuickCapture() }
                        .onChange(of: quickCaptureText) { _, newValue in
                            guard newValue.contains("\n") else { return }
                            quickCaptureText = newValue.replacingOccurrences(of: "\n", with: "")
                            commitQuickCapture()
                        }

                if quickCaptureText.isEmpty {
                    Text("Add a task...")
                        .foregroundStyle(AppTheme.colors.textSecondary)
                        .frame(minHeight: 28, alignment: .center)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 48)
        }
        .padding(.leading, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { quickCaptureFocused = true }
        .animation(.easeInOut(duration: 0.15), value: isBarIdle)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 5)
        .overlay(alignment: .bottomTrailing) {
            Button {
                commitQuickCapture()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(AppTheme.colors.primaryAction))
            }
            .buttonStyle(.plain)
            .opacity(hasValidCaptureContent ? 1 : 0)
            .allowsHitTesting(hasValidCaptureContent)
            .disabled(!hasValidCaptureContent)
            .animation(.easeInOut(duration: 0.15), value: hasValidCaptureContent)
            .accessibilityIdentifier("list-bar-submit")
            .padding(.trailing, 14)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, quickCaptureFocused ? 8 : 32)
        .animation(.easeInOut(duration: 0.2), value: quickCaptureFocused)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
    }

    private func commitQuickCapture() {
        let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            quickCaptureFocused = false
            return
        }
        quickCaptureText = ""
        viewModel?.commitQuickCapture(text: text, in: listID)
    }

    private func taskListRow(_ node: FlatTaskNode) -> some View {
        let task = node.task
        let sibs = viewModel?.siblings(of: task) ?? []
        return TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: {
                if task.isCompleted == false {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                viewModel?.toggleCompletion(for: task)
            },
            onDueDateAction: { action in
                switch action {
                case .none:
                    viewModel?.rescheduleTaskToNone(task)
                case .today:
                    viewModel?.rescheduleTaskToToday(task)
                case .tomorrow:
                    viewModel?.rescheduleTaskToTomorrow(task)
                case .thisWeekend:
                    viewModel?.rescheduleTaskToThisWeekend(task)
                case .nextWeek:
                    viewModel?.rescheduleTaskToNextWeek(task)
                case .custom:
                    presentScheduleSheet(for: task)
                }
            },
            onMoveToList: { viewModel?.moveTask(task, to: $0) },
            listSections: viewModel?.listSections ?? [],
            excludedListID: task.reminderList?.persistentModelID,
            onDelete: { viewModel?.delete(task: task) },
            onMoveToTop: sibs.count > 1 ? { viewModel?.moveToTop(task: task) } : nil,
            onMoveToBottom: sibs.count > 1 ? { viewModel?.moveToBottom(task: task) } : nil,
            onTap: {
                quickCaptureFocused = false
                editingTask = task
            },
            showsDueDate: true,
            showsListName: false,
            subtaskSummary: node.subtaskSummary,
            isSelecting: isSelecting,
            isSelected: selectedTasks.contains(task.persistentModelID),
            onSelectToggle: {
                if selectedTasks.contains(task.persistentModelID) {
                    selectedTasks.remove(task.persistentModelID)
                } else {
                    selectedTasks.insert(task.persistentModelID)
                }
            },
            isExpanded: !(viewModel?.collapsedTasks.contains(task.taskId ?? "") ?? false),
            onToggleExpand: isSelecting ? nil : {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel?.toggleTaskCollapsed(task.taskId ?? "")
                }
            }
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.leading, CGFloat(node.depth) * 20)
        .onDrag {
            guard !isSelecting else { return NSItemProvider() }
            viewModel?.draggedTaskId = task.taskId
            return NSItemProvider(object: (task.taskId ?? "") as NSString)
        }
        .onDrop(of: [.text], delegate: TaskDropDelegate(targetTask: task) { target, location in
            guard !isSelecting else { return }
            viewModel?.handleDrop(target: target, location: location)
        })
    }

    private func flatToTaskIndex(_ flatIndex: Int) -> Int {
        guard let vm = viewModel else { return 0 }
        guard flatIndex < vm.flatNodes.count else { return vm.tasks.count }
        return vm.tasks.firstIndex(where: { $0.persistentModelID == vm.flatNodes[flatIndex].task.persistentModelID }) ?? vm.tasks.count
    }

    private func presentScheduleSheet(for task: TaskItem) {
        scheduleConfig = ScheduleConfig(task: task)
    }

    private func bulkDelete() {
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
        for id in selectedTasks {
            if let task = listTasks.first(where: { $0.persistentModelID == id }) {
                viewModel?.delete(task: task)
            }
        }
        exitSelectionMode()
    }

    private func bulkToggleCompletion() {
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
        for id in selectedTasks {
            if let task = listTasks.first(where: { $0.persistentModelID == id }) {
                viewModel?.toggleCompletion(for: task)
            }
        }
    }
}
