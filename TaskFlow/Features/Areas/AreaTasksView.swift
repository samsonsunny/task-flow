import SwiftUI
import SwiftData

/// One domain's tasks: the Work and Personal tabs.
///
/// Tasks are grouped under their list, so the page answers "everything I filed here" rather
/// than "what is due".
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        FloatingAddButton {
                            newTaskConfig = NewTaskSheetConfig(
                                initialDate: nil,
                                initialListID: defaultListID
                            )
                        }
                    }
                }
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

    private var rowActions: TaskRowActions {
        TaskRowActions(
            toggleCompletion: { viewModel?.toggleCompletion(for: $0) },
            reschedule: { task, action in
                if action == .custom {
                    scheduleConfigTask = task
                } else {
                    viewModel?.rescheduleTask(task, to: action)
                }
            },
            delete: { viewModel?.delete($0) },
            open: { editingTask = $0 }
        )
    }

    @ViewBuilder
    private var listContent: some View {
        Group {
            if viewModel?.tasks.isEmpty ?? true {
                ContentUnavailableView(
                    "No \(displayName.lowercased()) tasks",
                    systemImage: areaName == AreaNames.work ? "briefcase" : "person.crop.circle",
                    description: Text("Tasks in your \(displayName) lists will appear here.")
                )
            } else {
                ScrollViewReader { proxy in
                    List {
                        Color.clear
                            .frame(height: 1)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .id("areaListTop")

                        ForEach(viewModel?.sections ?? []) { section in
                            listSection(section)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .refreshable { refresh() }
                    .padding(.horizontal, AppSpacing.sm)
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

    @ViewBuilder
    private func listSection(_ section: AreaTaskSection) -> some View {
        Section {
            ForEach(Array(section.tasks.enumerated()), id: \.element.id) { index, task in
                taskRow(task, isFirst: index == 0)
            }
            addTaskRow(for: section.list)
        } header: {
            Text(section.list.name)
                .font(AppFont.footnoteSemibold)
                .foregroundStyle(AppTheme.colors.textSecondary)
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func taskRow(_ task: TaskItem, isFirst: Bool) -> some View {
        TaskRowView(
            task: task,
            actions: rowActions,
            showsDueDate: true
        )
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(sectionBackground(top: isFirst, bottom: false))
    }

    private func addTaskRow(for list: ReminderList) -> some View {
        Button {
            Haptics.impact(.light)
            newTaskConfig = NewTaskSheetConfig(
                initialDate: nil,
                initialListID: list.persistentModelID
            )
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "plus")
                    .font(AppFont.subheadline.weight(.semibold))
                Text("Add Task")
                    .font(AppFont.subheadline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.rowVertical)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.colors.tint)
        .accessibilityLabel("Add task to \(list.name)")
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(sectionBackground(top: false, bottom: true))
    }

    @ViewBuilder
    private func sectionBackground(top: Bool, bottom: Bool) -> some View {
        let color = AppColors.groupedSurface
        if top {
            UnevenRoundedRectangle(
                topLeadingRadius: AppRadius.card,
                topTrailingRadius: AppRadius.card,
                style: .continuous
            )
            .fill(color)
        } else if bottom {
            UnevenRoundedRectangle(
                bottomLeadingRadius: AppRadius.card,
                bottomTrailingRadius: AppRadius.card,
                style: .continuous
            )
            .fill(color)
        } else {
            Rectangle()
                .fill(color)
        }
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
