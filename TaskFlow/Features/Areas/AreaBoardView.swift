import SwiftUI
import SwiftData

/// Horizontal list-based board for an area. Each column is one list; dragging a card to
/// another column moves the task to that list.
struct AreaBoardView: View {
    let viewModel: AreaTasksViewModel
    let onEditTask: (TaskItem) -> Void
    let onNewTask: (ReminderList) -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.boardLists) { list in
                        BoardColumnView(
                            list: list,
                            tasks: viewModel.tasks(in: list),
                            width: columnWidth(for: proxy.size.width),
                            height: max(0, proxy.size.height - 16),
                            onNewTask: { onNewTask(list) },
                            onEditTask: onEditTask,
                            onToggleCompletion: { viewModel.toggleCompletion(for: $0) },
                            onDropTaskID: { id in
                                guard let task = viewModel.tasks.first(where: {
                                    $0.persistentModelID == id
                                }) else { return false }
                                let moved = viewModel.moveTask(task, to: list)
                                if moved {
                                    Haptics.success()
                                } else {
                                    Haptics.impact(.light)
                                }
                                return moved
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(AppTheme.colors.pageBackground.ignoresSafeArea())
    }

    private func columnWidth(for availableWidth: CGFloat) -> CGFloat {
        min(320, max(250, availableWidth * 0.82))
    }
}

private struct BoardColumnView: View {
    let list: ReminderList
    let tasks: [TaskItem]
    let width: CGFloat
    let height: CGFloat
    let onNewTask: () -> Void
    let onEditTask: (TaskItem) -> Void
    let onToggleCompletion: (TaskItem) -> Void
    let onDropTaskID: (PersistentIdentifier) -> Bool

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if tasks.isEmpty {
                        Text("No tasks")
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppTheme.colors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            TaskRowView(
                                task: task,
                                isCompletedVisualState: task.isCompleted ?? false,
                                onToggleCompletion: { onToggleCompletion(task) },
                                onTap: { onEditTask(task) },
                                showsDueDate: true,
                                showsListName: false,
                                subtaskSummary: task.subtaskSummary
                            )
                            .onDrag {
                                Haptics.impact(.medium)
                                return NSItemProvider(
                                    object: task.persistentModelID.stableKey as NSString
                                )
                            }

                            if index < tasks.count - 1 {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }

                    Button {
                        Haptics.impact(.light)
                        onNewTask()
                    } label: {
                        Label("Add task", systemImage: "plus")
                            .font(AppFont.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.colors.tint)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .background(
                                AppTheme.colors.tint.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add task in \(list.name)")
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 72, for: .scrollContent)
        }
        .frame(width: width, height: height, alignment: .top)
        .background(AppTheme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? AppTheme.colors.tint : Color.clear,
                    lineWidth: 2
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .dropDestination(for: String.self) { items, _ in
            guard let key = items.first,
                  let id = PersistentIdentifier(stableKey: key)
            else { return false }
            return onDropTaskID(id)
        } isTargeted: { targeted in
            if targeted, !isTargeted {
                Haptics.selection()
            }
            withAnimation(.easeInOut(duration: 0.15)) {
                isTargeted = targeted
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: list.isBucket ? "tray" : "list.bullet")
                .font(AppFont.caption)
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(AppFont.headlineSemibold)
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .lineLimit(1)

                Text(taskCountLabel)
                    .font(AppFont.caption)
                    .foregroundStyle(AppTheme.colors.textTertiary)
            }

            Spacer(minLength: 0)

            Button {
                Haptics.impact(.light)
                onNewTask()
            } label: {
                Image(systemName: "plus")
                    .font(AppFont.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.tint)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.colors.tint.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New task in \(list.name)")
        }
    }

    private var taskCountLabel: String {
        tasks.count == 1 ? "1 task" : "\(tasks.count) tasks"
    }
}
