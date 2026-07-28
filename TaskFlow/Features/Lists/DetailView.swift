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
    @State private var newReminderConfig: NewReminderConfig?
    @State private var editingTask: TaskItem?
    @State private var isQuickCapturing = false
    @State private var quickCaptureText = ""
    @State private var collapsedTasks: Set<PersistentIdentifier> = []
    @State private var defaultCollapsed = true
    @State private var isSelecting = false
    @State private var selectedTasks: Set<PersistentIdentifier> = []
    @State private var savedCollapseState: Set<PersistentIdentifier> = []
    @State private var showDeleteConfirmation = false

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private func enterSelectionMode() {
        savedCollapseState = collapsedTasks
        collapsedTasks = []
        selectedTasks = []
        isSelecting = true
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
        viewModel?.update(tasks: listTasks, lists: allLists, allTasks: allTasks, now: Date(), collapsedTasks: collapsedTasks)
    }

    private func exitSelectionMode() {
        isSelecting = false
        selectedTasks = []
        collapsedTasks = savedCollapseState
        let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
        viewModel?.update(tasks: listTasks, lists: allLists, allTasks: allTasks, now: Date(), collapsedTasks: collapsedTasks)
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if let vm = viewModel {
                    if vm.flatNodes.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.flatNodes) { node in
                            taskListRow(node)
                                .transition(.scale.combined(with: .opacity))
                        }
                        .onMove { fromOffsets, toOffset in
                            let taskFromOffsets = IndexSet(fromOffsets.map { flatToTaskIndex($0) })
                            let taskToOffset = flatToTaskIndex(toOffset)
                            vm.moveTasks(fromOffsets: taskFromOffsets, toOffset: taskToOffset)
                        }
                    }
                }

                if isQuickCapturing && !isSelecting {
                    QuickCaptureRow(
                        text: $quickCaptureText,
                        onSubmit: { viewModel?.commitQuickCapture(text: $0, in: listID) },
                        onDismiss: { isQuickCapturing = false }
                    )
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.colors.appBackground)
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded { isQuickCapturing = false }
            )
            .navigationTitle(viewModel?.list?.name ?? "")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
            .quickCaptureScroll(isActive: isQuickCapturing, proxy: proxy)
        }
        .overlay(alignment: .bottomTrailing) {
            ReminderFloatingAddButton {
                isQuickCapturing = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
            .opacity(isQuickCapturing || isSelecting ? 0 : 1)
            .allowsHitTesting(!isQuickCapturing && !isSelecting)
            .animation(.easeInOut(duration: 0.15), value: isQuickCapturing)
        }
        .overlay(alignment: .bottom) {
            if isSelecting {
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
                .animation(.easeInOut(duration: 0.25), value: isSelecting)
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
                let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
                let taskIDs = Set(listTasks.map(\.persistentModelID))
                let rootTasks = listTasks.filter {
                    guard let parent = $0.parentTask else { return true }
                    return !taskIDs.contains(parent.persistentModelID)
                }
                let parentIDs = Set(rootTasks.filter { !$0.subtasks.isEmpty }.map(\.persistentModelID))
                collapsedTasks = parentIDs
                defaultCollapsed = false
            }
            viewModel = ListDetailViewModel(modelContext: modelContext, listID: listID)
            let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
            viewModel?.update(tasks: listTasks, lists: allLists, allTasks: allTasks, now: Date(), collapsedTasks: collapsedTasks)
        }
        .onChange(of: allTasks) { _, newTasks in
            let listTasks = newTasks.filter { $0.reminderList?.persistentModelID == listID }
            viewModel?.update(tasks: listTasks, lists: allLists, allTasks: newTasks, collapsedTasks: collapsedTasks)
        }
        .onChange(of: allLists) { _, newLists in
            let listTasks = allTasks.filter { $0.reminderList?.persistentModelID == listID }
            viewModel?.update(tasks: listTasks, lists: newLists, allTasks: allTasks, collapsedTasks: collapsedTasks)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No tasks")
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Tap + to add a task to this list.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
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
            onMoveToToday: viewModel?.canMoveToToday(task) == true ? { viewModel?.rescheduleTaskToToday(task) } : nil,
            onMoveToTomorrow: viewModel?.canMoveToTomorrow(task) == true ? { viewModel?.rescheduleTaskToTomorrow(task) } : nil,
            onMoveToNextWeek: viewModel?.canMoveToNextWeek(task) == true ? { viewModel?.rescheduleTaskToNextWeek(task) } : nil,
            onMoveToLater: task.dueDate != nil ? { viewModel?.rescheduleTaskToLater(task) } : nil,
            onSchedule: { presentScheduleSheet(for: task) },
            onMoveToList: { viewModel?.moveTask(task, to: $0) },
            listSections: viewModel?.listSections ?? [],
            onDelete: { viewModel?.delete(task: task) },
            onMoveToTop: sibs.count > 1 ? { viewModel?.moveToTop(task: task) } : nil,
            onMoveToBottom: sibs.count > 1 ? { viewModel?.moveToBottom(task: task) } : nil,
            onTap: {
                isQuickCapturing = false
                quickCaptureText = ""
                editingTask = task
            },
            showsDueDate: true,
            showsListName: false,
            nestingDepth: node.depth,
            subtaskCount: node.subtaskCount,
            isCollapsed: collapsedTasks.contains(task.persistentModelID),
            onToggleCollapse: {
                if collapsedTasks.contains(task.persistentModelID) {
                    collapsedTasks.remove(task.persistentModelID)
                } else {
                    collapsedTasks.insert(task.persistentModelID)
                }
                viewModel?.update(tasks: allTasks.filter { $0.reminderList?.persistentModelID == listID }, lists: allLists, allTasks: allTasks, collapsedTasks: collapsedTasks)
            },
            isSelecting: isSelecting,
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
