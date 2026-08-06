import SwiftUI
import SwiftData

struct CompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var viewModel: CompletedViewModel?
    @State private var editingTask: TaskItem?
    @State private var isSelecting = false
    @State private var selectedTasks: Set<PersistentIdentifier> = []
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            if let vm = viewModel {
                if vm.recentCompletedTasks.isEmpty {
                    emptyState
                } else {
                    ForEach(vm.groupedTasks, id: \.0) { sectionTitle, tasks in
                        Section {
                            ForEach(tasks) { task in
                                completedTaskRow(task)
                            }
                        } header: {
                            Text(sectionTitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.colors.textSecondary)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.colors.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSelecting {
                    Button("Done") {
                        isSelecting = false
                        selectedTasks = []
                    }
                } else {
                    Menu {
                        Button("Select Items") {
                            isSelecting = true
                            selectedTasks = []
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if isSelecting {
                BulkActionsToolbar(
                    selectedCount: selectedTasks.count,
                    onDelete: { showDeleteConfirmation = true },
                    onRescheduleToday: { },
                    onRescheduleTomorrow: { },
                    onRescheduleThisWeekend: { },
                    onRescheduleNextWeek: { },
                    onRescheduleCustom: { },
                    onRescheduleNone: { },
                    onMoveToList: { _ in },
                    listSections: [],
                    onSetPriority: { _ in },
                    onComplete: { },
                    onDone: {
                        isSelecting = false
                        selectedTasks = []
                    }
                )
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.25), value: isSelecting)
            }
        }
        .sheet(item: $editingTask) { task in
            ReminderEditorView(task: task)
        }
        .onAppear {
            viewModel = CompletedViewModel(modelContext: modelContext, appState: appState)
            viewModel?.update(tasks: allTasks)
        }
        .onChange(of: allTasks) { _, newTasks in
            viewModel?.update(tasks: newTasks)
        }
        .alert("Delete \(selectedTasks.count) task\(selectedTasks.count == 1 ? "" : "s")?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                bulkDelete()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No recently completed tasks")
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Tasks you complete will appear here for 30 days.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func bulkDelete() {
        for id in selectedTasks {
            if let task = allTasks.first(where: { $0.persistentModelID == id }) {
                viewModel?.delete(task)
            }
        }
        isSelecting = false
        selectedTasks = []
    }

    private func completedTaskRow(_ task: TaskItem) -> some View {
        let isUncompleting = viewModel?.justUncompleted.contains(task.taskId ?? "") ?? false

        return HStack(alignment: .center, spacing: 12) {
            if isSelecting {
                SelectionCircle(isSelected: selectedTasks.contains(task.persistentModelID))
                    .onTapGesture {
                        if selectedTasks.contains(task.persistentModelID) {
                            selectedTasks.remove(task.persistentModelID)
                        } else {
                            selectedTasks.insert(task.persistentModelID)
                        }
                    }
            } else {
                Button {
                    viewModel?.beginUncomplete(task)
                } label: {
                    ZStack {
                        Circle()
                            .stroke(isUncompleting ? AppTheme.colors.border : AppTheme.colors.primaryAction, lineWidth: 1.5)
                            .background(Circle().fill(isUncompleting ? AppTheme.colors.surface : AppTheme.colors.primaryAction))
                            .frame(width: 20, height: 20)

                        if !isUncompleting {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.18), value: isUncompleting)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Un-complete task")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.safeTitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(isUncompleting ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary)
                    .strikethrough(!isUncompleting)
                    .opacity(isUncompleting ? 1.0 : 0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut(duration: 0.18), value: isUncompleting)

                Text("\(CompletedViewModel.completionTimeLabel(for: task))  ·  \(task.listName)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.colors.textTertiary)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
        .background(
            selectedTasks.contains(task.persistentModelID) ? AppTheme.colors.primaryAction.opacity(0.12) : Color.clear
        )
        .animation(.easeInOut(duration: 0.18), value: selectedTasks.contains(task.persistentModelID))
        .onTapGesture {
            if isSelecting {
                if selectedTasks.contains(task.persistentModelID) {
                    selectedTasks.remove(task.persistentModelID)
                } else {
                    selectedTasks.insert(task.persistentModelID)
                }
            } else {
                editingTask = task
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isSelecting {
                Button(role: .destructive) {
                    viewModel?.delete(task)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
