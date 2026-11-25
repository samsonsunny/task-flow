import SwiftUI
import SwiftData

/// One domain's tasks: the Work and Personal tabs.
///
/// The list is flat and creation-ordered, so it answers "everything I filed here" rather than
/// "what is due".
struct AreaTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    let areaName: String

    init(areaName: String) {
        self.areaName = areaName
    }

    private var displayName: String {
        areaDisplayName(areaName)
    }

    @State private var viewModel: AreaTasksViewModel?
    @State private var editingTask: TaskItem?
    @State private var newTaskConfig: NewTaskSheetConfig?
    @State private var scheduleConfigTask: TaskItem?

    var body: some View {
        NavigationStack {
            listContent
                .overlay(alignment: .bottomTrailing) {
                    FloatingAddButton {
                        newTaskConfig = NewTaskSheetConfig(
                            initialDate: nil,
                            initialListID: defaultListID
                        )
                    }
                }
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
                .navigationTitle(displayName)
                .navigationBarTitleDisplayMode(.large)
                // Pushed rather than presented: the editor's toolbar buttons need a real stack.
                .navigationDestination(item: $editingTask) { task in
                    ReminderEditorView(task: task, embedInNavigationStack: false)
                }
        }
        .onAppear(perform: bootstrap)
        .onChange(of: areaName) { _, _ in bootstrap() }
        .onChange(of: groups) { _, _ in refresh() }
        .onChange(of: lists) { _, _ in refresh() }
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

    /// New tasks land in this area's Inbox bucket.
    private var defaultListID: ReminderList.ID? {
        guard let area = viewModel?.area else { return nil }
        return (
            area.inboxBucket
            ?? lists.first { $0.group?.persistentModelID == area.persistentModelID }
        )?.persistentModelID
    }

    @ViewBuilder
    private var listContent: some View {
        Group {
            if viewModel?.tasks.isEmpty ?? true {
                ContentUnavailableView(
                    "No \(displayName.lowercased()) tasks",
                    systemImage: areaName == AreaNames.work ? "briefcase" : "house",
                    description: Text("Tasks in your \(areaName) lists will appear here.")
                )
            } else {
                let tasks = viewModel?.tasks ?? []
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                                TaskRowView(
                                    task: task,
                                    isCompletedVisualState: task.isCompleted ?? false,
                                    onToggleCompletion: {
                                        Haptics.impact(.light)
                                        viewModel?.toggleCompletion(for: task)
                                    },
                                    onDueDateAction: { action in
                                        if action == .custom {
                                            scheduleConfigTask = task
                                        } else {
                                            viewModel?.rescheduleTask(task, to: action)
                                        }
                                    },
                                    onDelete: { viewModel?.delete(task) },
                                    onTap: { editingTask = task },
                                    showsDueDate: true,
                                    showsListName: true
                                )

                                if index < tasks.count - 1 {
                                    Divider()
                                        .padding(.leading, 54)
                                }
                            }
                        }
                        .id("areaListTop")
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous))
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 2)
                        .padding(.bottom, 100)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable { refresh() }
                    .onChange(of: appState.scrollToTopRequestIDs[areaName] ?? 0) { _, _ in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo("areaListTop", anchor: .top)
                        }
                    }
                }
            }
        }
        .background(AppTheme.colors.pageBackground.ignoresSafeArea())
    }

    private func bootstrap() {
        if viewModel?.areaName != areaName {
            viewModel = AreaTasksViewModel(modelContext: modelContext, areaName: areaName)
        }
        refresh()
    }

    private func refresh() {
        viewModel?.update(groups: groups, lists: lists, allTasks: allTasks)
    }
}

#Preview("Work") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedBothAreasFixture(into: container)
    return AreaTasksView(areaName: AreaNames.work)
        .modelContainer(container)
        .environment(AppState())
}

#Preview("Personal") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedBothAreasFixture(into: container)
    return AreaTasksView(areaName: AreaNames.personal)
        .modelContainer(container)
        .environment(AppState())
}
