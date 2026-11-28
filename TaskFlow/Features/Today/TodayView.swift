import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<TaskItem> { $0.isCompleted != true },
        sort: \TaskItem.createdAt,
        order: .reverse
    )
    private var tasks: [TaskItem]

    @State private var showingNewTask = false
    @State private var actions = TaskActionsViewModel()

    private var overdueTasks: [TaskItem] {
        tasks.filter(\.isOverdue).sorted { $0.safeDueDate < $1.safeDueDate }
    }

    private var dueTodayTasks: [TaskItem] {
        tasks
            .filter { Calendar.current.isDateInToday($0.dueDate ?? .distantPast) }
            .sorted { $0.safeDueDate < $1.safeDueDate }
    }

    var body: some View {
        NavigationStack {
            List {
                DomainIntroView(
                    eyebrow: "WEDNESDAY CALENDAR",
                    title: "Today",
                    message: "Overdue and due today, across Work and Home."
                )
                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20))
                .listRowBackground(Color(uiColor: .systemBackground))
                .listRowSeparator(.hidden)

                taskSection(
                    title: "Overdue",
                    subtitle: "Carry these forward with intention",
                    tasks: overdueTasks,
                    emptyText: "Nothing overdue. You are keeping pace."
                )

                taskSection(
                    title: "Due today",
                    subtitle: "Your commitments for today",
                    tasks: dueTodayTasks,
                    emptyText: "Nothing due today."
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground).opacity(0.4))
            .navigationTitle("Today")
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
                NewTaskSheet(defaultDomain: nil)
            }
            .animation(.easeOut(duration: 0.2), value: actions.revision)
        }
    }

    @ViewBuilder
    private func taskSection(
        title: String,
        subtitle: String,
        tasks: [TaskItem],
        emptyText: String
    ) -> some View {
        Section {
            if tasks.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .listRowSeparator(.hidden)
            } else {
                ForEach(tasks) { task in
                    TaskRowView(task: task, showsDomain: true)
                        .taskActions(
                            task: task,
                            onToggle: { actions.toggleCompletion(for: task, in: modelContext) },
                            onDelete: { actions.delete(task, in: modelContext) }
                        )
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        .listRowBackground(Color(uiColor: .systemBackground))
                        .listRowSeparator(.hidden)
                }
            }
        } header: {
            EditorialSectionHeader(title: title, subtitle: subtitle)
        }
    }
}
