import SwiftUI
import SwiftData

struct OverdueTasksView: View {
    @Environment(\.modelContext) private var modelContext
    
    private var overduePredicate: Predicate<TaskItem> {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        return #Predicate<TaskItem> { task in
            task.isCompleted == false && task.storedReminderReferenceDate != nil && task.storedReminderReferenceDate! < todayStart
        }
    }
    
    var body: some View {
        FilteredTaskListView(
            title: "Overdue",
            predicate: overduePredicate,
            emptyStateType: .noOverdue
        ) { task in
            NavigationLink(value: task) {
                TaskRowView(task: task)
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    reschedule(task, daysFromToday: 0)
                } label: {
                    Label("Move to Today", systemImage: "calendar")
                }
                .tint(AppTheme.colors.primary)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    markDone(task)
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .tint(AppTheme.colors.success)
            }
            .contextMenu {
                Button("Mark Done") { markDone(task) }
                Button("Move to Today") { reschedule(task, daysFromToday: 0) }
                Button("Move to Tomorrow") { reschedule(task, daysFromToday: 1) }
                Button("Move to Next Week") { reschedule(task, daysFromToday: 7) }
            }
        }
    }
    
    private func reschedule(_ task: TaskItem, daysFromToday: Int) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let newDate = calendar.date(byAdding: .day, value: daysFromToday, to: todayStart) ?? todayStart
        task.dueDate = newDate
        modelContext.insert(task)
        NotificationManager.shared.scheduleReminder(for: task)
    }

    private func markDone(_ task: TaskItem) {
        task.isCompleted = true
        task.completionDate = Date()
        modelContext.insert(task)
        NotificationManager.shared.cancelReminder(for: task)
    }
}

