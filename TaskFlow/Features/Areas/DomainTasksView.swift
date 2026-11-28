import SwiftData
import SwiftUI

struct DomainTasksView: View {
    let domainName: String

    @Environment(\.modelContext) private var modelContext
    @Query private var lists: [ReminderList]
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted != true }, sort: \TaskItem.createdAt, order: .reverse)
    private var tasks: [TaskItem]

    @State private var showingNewTask = false

    private var displayName: String {
        domainName == "Personal" ? "Home" : domainName
    }

    private var domainLists: [ReminderList] {
        lists.filter { $0.group?.name == domainName }
    }

    private var domainTasks: [TaskItem] {
        tasks.filter { $0.reminderList?.group?.name == domainName }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(domainLists) { list in
                    Section(list.name) {
                        let items = domainTasks.filter {
                            $0.reminderList?.persistentModelID == list.persistentModelID
                        }
                        if items.isEmpty {
                            Text("No Tasks")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(items) { task in
                                taskRow(task)
                            }
                            .onDelete { offsets in
                                deleteTasks(offsets, from: items)
                            }
                        }
                    }
                }
            }
            .navigationTitle(displayName)
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
                NewTaskSheet(defaultDomain: domainName)
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
