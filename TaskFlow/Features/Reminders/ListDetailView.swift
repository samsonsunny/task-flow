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
    @State private var justCompleted: Set<String> = []
    @State private var isQuickCapturing = false
    @State private var quickCaptureText = ""
    @FocusState private var isQuickCaptureFocused: Bool

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var list: ReminderList? {
        allLists.first { $0.persistentModelID == listID }
    }

    private var tasks: [TaskItem] {
        allTasks.filter {
            guard $0.reminderList?.persistentModelID == listID else { return false }
            if $0.isCompleted == true {
                return justCompleted.contains($0.taskId ?? "")
            }
            return true
        }
    }

    var body: some View {
        List {
            if isQuickCapturing {
                quickCaptureRow
            }

            if tasks.isEmpty {
                emptyState
            } else {
                ForEach(tasks) { task in
                    taskListRow(task)
                        .transition(.scale.combined(with: .opacity))
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
        .animation(.easeInOut, value: tasks.count)
        .overlay(alignment: .bottomTrailing) {
            ReminderFloatingAddButton {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isQuickCapturing = true
                }
                isQuickCaptureFocused = true
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
                    let notif = NotificationService.shared
                    if let taskId = config.task.taskId {
                        notif.cancel(taskId: taskId)
                    }
                    if let date = dueDate {
                        if hasTime {
                            config.task.dueDate = date
                            notif.schedule(for: config.task)
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
        .onChange(of: isQuickCaptureFocused) { _, focused in
            if !focused {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isQuickCapturing = false
                    quickCaptureText = ""
                }
            }
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
            onDelete: {
                if let taskId = task.taskId {
                    NotificationService.shared.cancel(taskId: taskId)
                }
                modelContext.delete(task)
            },
            onTap: { editingTask = task },
            showsDueDate: true,
            showsListName: false
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
                if let taskId = task.taskId {
                    NotificationService.shared.cancel(taskId: taskId)
                }
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
        let next = !(task.isCompleted ?? false)
        if next {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if let id = task.taskId {
                justCompleted.insert(id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak task] in
                    guard let task, task.isCompleted == true else { return }
                    withAnimation {
                        justCompleted.remove(id)
                    }
                }
            }
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            task.isCompleted = next
            task.completionDate = next ? Date() : nil
            if next, let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
        }
    }

    private func rescheduleTaskToToday(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        task.dueDate = Calendar.current.startOfDay(for: now)
    }

    private func rescheduleTaskToTomorrow(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        task.dueDate = calendar.date(byAdding: .day, value: 1, to: todayStart)
    }

    private func rescheduleTaskToLater(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
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

    private var quickCaptureRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.colors.primaryAction)
                .frame(width: 20, height: 20)

            TextField("New Reminder", text: $quickCaptureText)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.colors.textPrimary)
                .focused($isQuickCaptureFocused)
                .onSubmit(commitQuickCapture)
                .submitLabel(.done)
                .accessibilityIdentifier("quick-capture-field")

            Button {
                openQuickCaptureEditor()
            } label: {
                Image(systemName: "chevron.right.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.colors.textSecondary)
            }
            .accessibilityIdentifier("quick-capture-detail")
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isQuickCapturing = false
                    quickCaptureText = ""
                }
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func commitQuickCapture() {
        let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        guard let currentList = list else { return }

        let task = TaskItem(taskTitle: text, dueDate: nil)
        task.createdAt = Date()
        task.reminderList = currentList
        modelContext.insert(task)

        quickCaptureText = ""
        isQuickCaptureFocused = true
    }

    private func openQuickCaptureEditor() {
        let text = quickCaptureText.trimmingCharacters(in: .whitespacesAndNewlines)
        newReminderConfig = NewReminderConfig(initialDate: nil, initialListID: listID, initialTitle: text)
        quickCaptureText = ""
        isQuickCapturing = false
    }
}
