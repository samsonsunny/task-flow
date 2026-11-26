import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                MainView()
            } else {
                ProgressView()
            }
        }
        .task {
            isReady = true
        }
    }
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted != true }, sort: \TaskItem.createdAt, order: .reverse)
    private var tasks: [TaskItem]

    @State private var showingNewTask = false

    private var overdueTasks: [TaskItem] {
        tasks.filter(\.isOverdue)
    }

    private var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(calendar.startOfDay(for: dueDate), inSameDayAs: today)
        }
    }

    private var remainingTasks: [TaskItem] {
        let todayIDs = Set(todayTasks.map(\.persistentModelID))
        return tasks.filter { !$0.isOverdue && !todayIDs.contains($0.persistentModelID) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Domains") {
                    ForEach(groups.filter(\.isLocked)) { group in
                        Text(group.name)
                    }
                }

                Section("Lists") {
                    ForEach(lists) { list in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(list.name)
                            Text(list.group?.name ?? "No Domain")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !overdueTasks.isEmpty {
                    Section("Overdue") {
                        ForEach(overdueTasks) { task in
                            taskRow(task)
                        }
                        .onDelete { offsets in
                            deleteTasks(offsets, from: overdueTasks)
                        }
                    }
                }

                if !todayTasks.isEmpty {
                    Section("Today") {
                        ForEach(todayTasks) { task in
                            taskRow(task)
                        }
                        .onDelete { offsets in
                            deleteTasks(offsets, from: todayTasks)
                        }
                    }
                }

                Section("Tasks") {
                    ForEach(remainingTasks) { task in
                        taskRow(task)
                    }
                    .onDelete { offsets in
                        deleteTasks(offsets, from: remainingTasks)
                    }
                }
            }
            .navigationTitle("TaskFlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Task")
                }
            }
            .sheet(isPresented: $showingNewTask) {
                NewTaskSheet()
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(task.safeTitle)
            if let dueDate = task.dueDate {
                Text(dueDate.formatted(date: .abbreviated, time: task.safeHasTime ? .shortened : .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func deleteTasks(_ offsets: IndexSet, from tasks: [TaskItem]) {
        for index in offsets {
            modelContext.delete(tasks[index])
        }
        try? modelContext.save()
    }
}

private struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.sortOrder, order: .forward) private var lists: [ReminderList]

    @State private var title = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var selectedListID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("List") {
                    Picker("List", selection: $selectedListID) {
                        Text("None").tag(Optional<PersistentIdentifier>.none)
                        ForEach(lists) { list in
                            Text(list.name).tag(Optional(list.persistentModelID))
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addTask() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let list = lists.first { $0.persistentModelID == selectedListID }
        let task = TaskItem(taskTitle: trimmed, dueDate: hasDueDate ? dueDate : nil, reminderList: list)
        task.hasTime = hasDueDate
        modelContext.insert(task)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskItem.self, ReminderList.self, ReminderListGroup.self, ReminderTag.self])
}
