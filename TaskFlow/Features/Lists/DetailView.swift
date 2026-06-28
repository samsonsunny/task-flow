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
    @State private var skipNextDismiss = false
    @FocusState private var isQuickCaptureFocused: Bool

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if isQuickCapturing {
                    quickCaptureRow
                }

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

                    rootDropZone
                }
            }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.colors.appBackground)
            .navigationTitle(viewModel?.list?.name ?? "")
            .navigationBarTitleDisplayMode(.large)
            .animation(.easeInOut, value: viewModel?.flatNodes.count ?? 0)
            .onChange(of: isQuickCapturing) { _, newValue in
                if newValue {
                    withAnimation { proxy.scrollTo("quick-capture", anchor: .top) }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ReminderFloatingAddButton {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isQuickCapturing = true
                }
                isQuickCaptureFocused = true
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
                        isQuickCapturing = false
                        quickCaptureText = ""
                    }
                }
            }
        }
        .onAppear {
            viewModel = ListDetailViewModel(modelContext: modelContext, listID: listID)
            viewModel?.update(tasks: allTasks, lists: allLists, allTasks: allTasks, now: Date())
        }
        .onChange(of: allTasks) { _, newTasks in
            viewModel?.update(tasks: newTasks, lists: allLists, allTasks: newTasks)
        }
        .onChange(of: allLists) { _, newLists in
            viewModel?.update(tasks: allTasks, lists: newLists, allTasks: allTasks)
        }
    }

    private var rootDropZone: some View {
        Color.clear
            .frame(height: 1)
            .contentShape(Rectangle())
            .onDrop(of: [.text], isTargeted: nil) { _ in
                viewModel?.moveTaskToRoot()
                return true
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No reminders")
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)

            Text("Tap + to add a reminder to this list.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
    }

    private func taskListRow(_ node: FlatTaskNode) -> some View {
        let task = node.task
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
            onMoveToLater: task.dueDate != nil ? { viewModel?.rescheduleTaskToLater(task) } : nil,
            onSchedule: { presentScheduleSheet(for: task) },
            onMoveToList: { viewModel?.moveTask(task, to: $0) },
            availableLists: viewModel?.otherLists ?? [],
            onDelete: { viewModel?.delete(task: task) },
            onTap: { editingTask = task },
            showsDueDate: true,
            showsListName: false,
            nestingDepth: node.depth,
            subtaskCount: node.subtaskCount,
            isCollapsed: viewModel?.collapsedTasks.contains(task.persistentModelID) == true,
            onToggleCollapse: { viewModel?.toggleCollapse(task) }
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .onDrag {
            viewModel?.draggedTaskId = task.taskId
            return NSItemProvider(object: (task.taskId ?? "") as NSString)
        }
        .onDrop(of: [.text], delegate: TaskDropDelegate(targetTask: task) { target, location in
            viewModel?.handleDrop(target: target, location: location)
        })
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel?.delete(task: task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func flatToTaskIndex(_ flatIndex: Int) -> Int {
        guard let vm = viewModel else { return 0 }
        guard flatIndex < vm.flatNodes.count else { return vm.tasks.count }
        return vm.tasks.firstIndex(where: { $0.persistentModelID == vm.flatNodes[flatIndex].task.persistentModelID }) ?? vm.tasks.count
    }

    private func presentScheduleSheet(for task: TaskItem) {
        viewModel?.presentScheduleSheet(for: task)
        scheduleConfig = ScheduleConfig(task: task)
    }

    private var quickCaptureRow: some View {
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
        .id("quick-capture")
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isQuickCapturing = false
                    quickCaptureText = ""
                }
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func commitQuickCapture() {
        let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        skipNextDismiss = true
        viewModel?.commitQuickCapture(text: text, in: listID)
        quickCaptureText = ""
        isQuickCaptureFocused = true
    }

    private func openQuickCaptureEditor() {
        let (title, targetListID) = viewModel?.openQuickCaptureEditor(text: quickCaptureText, listID: listID) ?? (quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines), listID)
        newReminderConfig = NewReminderConfig(initialDate: nil, initialListID: targetListID, initialTitle: title)
        quickCaptureText = ""
        isQuickCapturing = false
    }
}
