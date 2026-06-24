import SwiftUI
import SwiftData

struct CompletedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    private static let maxAgeDays = 30
    @State private var editingTask: TaskItem?

    private var recentCompletedTasks: [TaskItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.maxAgeDays, to: Date()) ?? Date()
        return allTasks.filter { task in
            guard task.isCompleted == true else { return false }
            let completionDate = task.completionDate ?? task.createdAt ?? Date()
            return completionDate >= cutoff
        }
    }

    private var groupedTasks: [(String, [TaskItem])] {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart)!

        var today: [TaskItem] = []
        var yesterday: [TaskItem] = []
        var thisWeek: [TaskItem] = []
        var earlier: [TaskItem] = []

        for task in recentCompletedTasks {
            let date = task.completionDate ?? task.createdAt ?? Date()
            let dayStart = calendar.startOfDay(for: date)

            if calendar.isDate(dayStart, inSameDayAs: todayStart) {
                today.append(task)
            } else if calendar.isDate(dayStart, inSameDayAs: yesterdayStart) {
                yesterday.append(task)
            } else if dayStart >= weekStart {
                thisWeek.append(task)
            } else {
                earlier.append(task)
            }
        }

        var result: [(String, [TaskItem])] = []
        if !today.isEmpty { result.append(("Today", today)) }
        if !yesterday.isEmpty { result.append(("Yesterday", yesterday)) }
        if !thisWeek.isEmpty { result.append(("This Week", thisWeek)) }
        if !earlier.isEmpty { result.append(("Earlier", earlier)) }
        return result
    }

    var body: some View {
        List {
            if recentCompletedTasks.isEmpty {
                emptyState
            } else {
                ForEach(groupedTasks, id: \.0) { sectionTitle, tasks in
                    Section {
                        ForEach(tasks) { task in
                            completedTaskRow(task)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        if let taskId = task.taskId {
                                            NotificationService.shared.cancel(taskId: taskId)
                                        }
                                        modelContext.delete(task)
                                        try? modelContext.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.colors.appBackground)
        .sheet(item: $editingTask) { task in
            ReminderEditorView(task: task)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No recently completed reminders")
                .font(.headline)
                .foregroundStyle(AppTheme.colors.textPrimary)
            Text("Reminders you complete will appear here for 30 days.")
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

    private func completedTaskRow(_ task: TaskItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                uncomplete(task)
            } label: {
                ZStack {
                    Circle()
                        .stroke(AppTheme.colors.primaryAction, lineWidth: 1.5)
                        .background(Circle().fill(AppTheme.colors.primaryAction))
                        .frame(width: 20, height: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.colors.textOnPrimaryAction)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Un-complete task")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.safeTitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .strikethrough()
                    .opacity(0.82)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(destinationLabel(for: task))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
        .onTapGesture {
            editingTask = task
        }
    }

    private func destinationLabel(for task: TaskItem) -> String {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        guard let dueDate = task.dueDate else {
            return "Will reappear in Later"
        }

        let dueStart = calendar.startOfDay(for: dueDate)
        if dueStart < todayStart {
            return "Was overdue"
        } else if calendar.isDate(dueStart, inSameDayAs: todayStart) {
            return "Will reappear in Today"
        } else if calendar.isDateInTomorrow(dueStart) {
            return "Will reappear in Tomorrow"
        } else {
            return "Will reappear in Upcoming"
        }
    }

    private func uncomplete(_ task: TaskItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            task.isCompleted = false
            task.completionDate = nil
        }
        if task.safeHasTime {
            NotificationService.shared.schedule(for: task)
        }
    }
}
