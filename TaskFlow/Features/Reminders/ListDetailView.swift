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
    @Environment(\.editMode) private var editMode
    let listID: ReminderList.ID

    @Query(sort: \TaskItem.sortOrder, order: .forward) private var allTasks: [TaskItem]
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
                .onMove { fromOffsets, toOffset in
                    moveTasks(fromOffsets: fromOffsets, toOffset: toOffset)
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

    private var otherLists: [ReminderList] {
        allLists.filter { $0.persistentModelID != listID }
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
            onMoveToList: { moveTask(task, to: $0) },
            availableLists: otherLists,
            onDelete: { modelContext.delete(task) },
            onTap: { editingTask = task }
        )
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .onDrag {
            let id = task.taskId ?? String(describing: task.persistentModelID)
            return NSItemProvider(object: id as NSString)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func moveTask(_ task: TaskItem, to list: ReminderList) {
        task.reminderList = list
        assignSortOrder(for: task, in: list)
        try? modelContext.save()
    }

    private func assignSortOrder(for task: TaskItem, in list: ReminderList) {
        let listTasks = allTasks.filter {
            $0.reminderList?.persistentModelID == list.persistentModelID &&
            $0.persistentModelID != task.persistentModelID
        }
        let lastOrder = listTasks.compactMap { $0.sortOrder }.sorted().last
        task.sortOrder = midpoint(between: lastOrder, and: nil)
    }

    private func moveTasks(fromOffsets: IndexSet, toOffset: Int) {
        withAnimation(.easeInOut(duration: 0.18)) {
            var mutableTasks = tasks
            let sortedFrom = fromOffsets.sorted()

            let moved = sortedFrom.reversed().map { mutableTasks.remove(at: $0) }
            let adjustedTo = toOffset > sortedFrom.first! ? toOffset - moved.count : toOffset
            let insertAt = min(adjustedTo, mutableTasks.count)

            mutableTasks.insert(contentsOf: moved, at: insertAt)

            var lower = insertAt > 0 ? mutableTasks[insertAt - 1].sortOrder : nil
            for i in insertAt..<(insertAt + moved.count) {
                let upper = (i + 1) < mutableTasks.count ? mutableTasks[i + 1].sortOrder : nil

                if let newOrder = midpoint(between: lower, and: upper) {
                    mutableTasks[i].sortOrder = newOrder
                } else {
                    if let upperStr = upper {
                        let widened = widen(upperStr)
                        if let upperTask = mutableTasks.first(where: { $0.sortOrder == upperStr }) {
                            upperTask.sortOrder = widened
                        }
                        mutableTasks[i].sortOrder = midpoint(between: lower, and: widened) ?? ""
                    } else {
                        mutableTasks[i].sortOrder = ""
                    }
                }

                lower = mutableTasks[i].sortOrder
            }

            try? modelContext.save()
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
