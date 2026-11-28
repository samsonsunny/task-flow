import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                MainTabView()
            } else {
                ProgressView()
            }
        }
        .task {
            isReady = true
        }
    }
}

struct NewTaskSheet: View {
    let defaultDomain: String?

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
            .onAppear {
                if selectedListID == nil {
                    selectedListID = lists.first { $0.group?.name == defaultDomain }?.persistentModelID
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
