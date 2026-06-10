import Combine
import SwiftUI
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

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let listID: ReminderList.ID

    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @Query(sort: \ReminderList.createdAt) private var allLists: [ReminderList]

    @State private var now = Date()
    @State private var scheduleConfig: ScheduleConfig?
    @State private var newReminderConfig: NewReminderConfig?
    @State private var editingTask: TaskItem?

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var list: ReminderList? {
        allLists.first { $0.persistentModelID == listID }
    }

    private var tasks: [TaskItem] {
        allTasks.filter {
            $0.reminderList?.persistentModelID == listID && $0.isCompleted != true
        }
    }

    var body: some View {
        List {
            if tasks.isEmpty {
                emptyState
            } else {
                ForEach(tasks) { task in
                    taskListRow(task)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.colors.appBackground)
        .navigationTitle(list?.name ?? "")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottomTrailing) {
            ReminderFloatingAddButton {
                newReminderConfig = NewReminderConfig(initialDate: nil, initialListID: listID, initialTitle: "")
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .onReceive(refreshTimer) { fireDate in
            now = fireDate
        }
        .sheet(item: $scheduleConfig) { config in
            TaskScheduleDatePickerSheet(
                isPresented: Binding(
                    get: { scheduleConfig != nil },
                    set: { if !$0 { scheduleConfig = nil } }
                ),
                initialDueDate: config.task.dueDate,
                onCommit: { dueDate, hasTime in
                    if let date = dueDate {
                        if hasTime {
                            config.task.dueDate = date
                        } else {
                            config.task.dueDate = Calendar.current.startOfDay(for: date)
                        }
                    } else {
                        config.task.dueDate = nil
                    }
                }
            )
        }
        .sheet(item: $newReminderConfig) { config in
            ReminderEditorView(initialDate: config.initialDate, initialListID: config.initialListID, initialTitle: config.initialTitle)
        }
        .sheet(item: $editingTask) { task in
            ReminderEditorView(task: task)
        }
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

    private func taskListRow(_ task: TaskItem) -> some View {
        TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: { toggleCompletion(for: task) },
            onMoveToToday: canMoveToToday(task) ? { rescheduleTaskToToday(task) } : nil,
            onMoveToTomorrow: canMoveToTomorrow(task) ? { rescheduleTaskToTomorrow(task) } : nil,
            onMoveToLater: task.dueDate != nil ? { rescheduleTaskToLater(task) } : nil,
            onSchedule: { presentScheduleSheet(for: task) },
            onDelete: { modelContext.delete(task) },
            onTap: { editingTask = task }
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func dueDateColor(for task: TaskItem) -> Color? {
        guard let dueDate = task.dueDate else { return nil }
        return Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: now)
            ? AppTheme.colors.error
            : AppTheme.colors.textSecondary
    }

    private func presentScheduleSheet(for task: TaskItem) {
        scheduleConfig = ScheduleConfig(task: task)
    }

    private func toggleCompletion(for task: TaskItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            let next = !(task.isCompleted ?? false)
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
        }
    }

    private func rescheduleTaskToToday(_ task: TaskItem) {
        task.dueDate = Calendar.current.startOfDay(for: now)
    }

    private func rescheduleTaskToTomorrow(_ task: TaskItem) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        task.dueDate = calendar.date(byAdding: .day, value: 1, to: todayStart)
    }

    private func rescheduleTaskToLater(_ task: TaskItem) {
        task.dueDate = nil
    }

    private func canMoveToToday(_ task: TaskItem) -> Bool {
        guard let dueDate = task.dueDate else { return true }
        return !Calendar.current.isDateInToday(dueDate)
    }

    private func canMoveToTomorrow(_ task: TaskItem) -> Bool {
        guard let dueDate = task.dueDate else { return true }
        return !Calendar.current.isDateInTomorrow(dueDate)
    }
}
