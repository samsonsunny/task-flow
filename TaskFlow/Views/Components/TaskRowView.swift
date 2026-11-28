import Observation
import SwiftData
import SwiftUI

/// Owns task mutations so views only observe state and delegate intent.
@Observable
final class TaskActionsViewModel {
    private(set) var revision = 0

    func toggleCompletion(for task: TaskItem, in modelContext: ModelContext) {
        let shouldComplete = task.isCompleted != true
        task.isCompleted = shouldComplete
        task.completionDate = shouldComplete ? Date() : nil
        if shouldComplete {
            task.completeDescendants()
        } else {
            task.uncompleteDescendants()
        }
        save(in: modelContext)
    }

    func delete(_ task: TaskItem, in modelContext: ModelContext) {
        task.deleteDescendants()
        modelContext.delete(task)
        save(in: modelContext)
    }

    private func save(in modelContext: ModelContext) {
        try? modelContext.save()
        update()
    }

    func update() {
        revision += 1
    }
}

/// One row for Work, Home, Search, and list details.
struct TaskRowView: View {
    let task: TaskItem
    var showsDomain = false
    var dateStyle: Date.FormatStyle.DateStyle = .abbreviated
    var onToggle: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            completionButton
            VStack(alignment: .leading, spacing: 5) {
                Text(task.safeTitle)
                    .font(.body.weight(task.isCompleted == true ? .regular : .semibold))
                    .foregroundStyle(task.isCompleted == true ? .secondary : .primary)
                    .strikethrough(task.isCompleted == true, color: .secondary)
                metadata
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private var completionButton: some View {
        Button {
            onToggle?()
        } label: {
            Image(systemName: task.isCompleted == true ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(task.isCompleted == true ? Color.accentColor : Color.secondary)
                .frame(width: 24)
        }
        .buttonStyle(.plain)
        .disabled(onToggle == nil)
        .accessibilityLabel(task.isCompleted == true ? "Mark incomplete" : "Mark complete")
    }

    private var metadata: some View {
        HStack(spacing: 8) {
            if task.isOverdue && task.isCompleted != true {
                Text("Overdue")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.red)
            }
            if let dueDate = task.dueDate {
                Text(dueDate.formatted(date: dateStyle, time: task.safeHasTime ? .shortened : .omitted))
            }
            if showsDomain, let domain = task.reminderList?.group?.name {
                Text(domain == "Personal" ? "Home" : domain)
            }
            if task.safeIsFlagged {
                Image(systemName: "flag.fill")
                    .accessibilityLabel("Flagged")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

private struct TaskRowActions: ViewModifier {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    onToggle()
                } label: {
                    Label(
                        task.isCompleted == true ? "Undo" : "Done",
                        systemImage: task.isCompleted == true ? "arrow.uturn.backward" : "checkmark"
                    )
                }
                .tint(Color.accentColor)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .contextMenu {
                Button {
                    onToggle()
                } label: {
                    Label(
                        task.isCompleted == true ? "Mark Incomplete" : "Mark Complete",
                        systemImage: task.isCompleted == true ? "circle" : "checkmark.circle"
                    )
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

extension View {
    func taskActions(
        task: TaskItem,
        onToggle: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(TaskRowActions(task: task, onToggle: onToggle, onDelete: onDelete))
    }
}
