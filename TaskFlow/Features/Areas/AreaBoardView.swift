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
        .background(AppTheme.colors.appBackground)
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
                LazyVStack(spacing: 10) {
                    if tasks.isEmpty {
                        Text("No tasks")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.colors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(tasks) { task in
                            BoardTaskCard(
                                task: task,
                                onToggleCompletion: { onToggleCompletion(task) },
                                onTap: { onEditTask(task) }
                            )
                            .onDrag {
                                Haptics.impact(.medium)
                                return NSItemProvider(
                                    object: task.persistentModelID.stableKey as NSString
                                )
                            }
                        }
                    }

                    Button {
                        Haptics.impact(.light)
                        onNewTask()
                    } label: {
                        Label("Add task", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
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
                .font(.caption)
                .foregroundStyle(AppTheme.colors.textSecondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .lineLimit(1)

                Text(taskCountLabel)
                    .font(.caption)
                    .foregroundStyle(AppTheme.colors.textTertiary)
            }

            Spacer(minLength: 0)

            Button {
                Haptics.impact(.light)
                onNewTask()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
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

private struct BoardTaskCard: View {
    let task: TaskItem
    let onToggleCompletion: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: {
                Haptics.impact(.light)
                onToggleCompletion()
            }) {
                Image(systemName: task.isCompleted == true ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(
                        task.isCompleted == true
                            ? AppTheme.colors.primaryAction
                            : AppTheme.colors.textTertiary
                    )
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted == true ? "Mark active" : "Mark complete")

            VStack(alignment: .leading, spacing: 6) {
                Text(task.safeTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .strikethrough(task.isCompleted == true, color: AppTheme.colors.textSecondary)

                if hasMetadata {
                    HStack(spacing: 8) {
                        if let dueText {
                            Label(dueText, systemImage: "calendar")
                                .foregroundStyle(task.isOverdue
                                    ? AppTheme.colors.error
                                    : AppTheme.colors.textSecondary)
                        }

                        if task.safeIsFlagged {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(AppTheme.colors.warning)
                        }

                        if task.priority != .none {
                            Label(task.priority.title, systemImage: "exclamationmark.circle")
                                .foregroundStyle(AppTheme.colors.textSecondary)
                        }
                    }
                    .font(.caption2)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.colors.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.colors.borderSubtle, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onTap)
    }

    private var hasMetadata: Bool {
        dueText != nil || task.safeIsFlagged || task.priority != .none
    }

    private var dueText: String? {
        guard let dueDate = task.dueDate else { return nil }
        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) { return "Today" }
        if calendar.isDateInTomorrow(dueDate) { return "Tomorrow" }
        if task.isOverdue { return "Overdue" }
        return Self.dateFormatter.string(from: dueDate)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()
}
