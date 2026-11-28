import SwiftData
import SwiftUI

struct DomainTasksView: View {
    let domainName: String

    @Environment(\.modelContext) private var modelContext
    @Query private var lists: [ReminderList]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]

    @State private var showingNewTask = false
    @State private var actions = TaskActionsViewModel()

    private var isWork: Bool { domainName == "Work" }
    private var displayName: String { isWork ? "Work" : "Home" }
    private var eyebrow: String { isWork ? "WORKSPACE" : "PERSONAL" }
    private var contextMessage: String {
        isWork
            ? "Your professional responsibilities, arranged for focus."
            : "The people, plans, and routines that shape your days at home."
    }

    private var domainLists: [ReminderList] {
        lists
            .filter { $0.group?.name == domainName }
            .sorted { lhs, rhs in
                let leftOrder = Int(lhs.sortOrder ?? "") ?? Int.max
                let rightOrder = Int(rhs.sortOrder ?? "") ?? Int.max
                if leftOrder != rightOrder { return leftOrder < rightOrder }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private var domainTasks: [TaskItem] {
        tasks.filter { $0.reminderList?.group?.name == domainName }
    }

    private var openTasks: [TaskItem] {
        domainTasks.filter { $0.isCompleted != true }
    }

    private var attentionTasks: [TaskItem] {
        openTasks
            .filter { task in
                guard let dueDate = task.dueDate else { return false }
                return task.isOverdue || Calendar.current.isDateInToday(dueDate)
            }
            .sorted { $0.safeDueDate < $1.safeDueDate }
    }

    private var upcomingGroups: [UpcomingGroup] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let horizon = calendar.date(byAdding: .day, value: 8, to: todayStart) ?? todayStart
        let grouped = Dictionary(
            grouping: openTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                let start = calendar.startOfDay(for: dueDate)
                return start > todayStart && start < horizon
            }
        ) { calendar.startOfDay(for: $0.safeDueDate) }

        return grouped.keys.sorted().map { date in
            UpcomingGroup(
                date: date,
                tasks: grouped[date]?.sorted { $0.safeDueDate < $1.safeDueDate } ?? []
            )
        }
    }

    private var completedTasks: [TaskItem] {
        domainTasks
            .filter { $0.isCompleted == true }
            .sorted {
                ($0.completionDate ?? $0.safeCreatedAt) > ($1.completionDate ?? $1.safeCreatedAt)
            }
    }

    var body: some View {
        NavigationStack {
            List {
                attentionSection
                upcomingSection
                listsSection
                completedSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground).opacity(0.4))
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
            .animation(.easeOut(duration: 0.2), value: actions.revision)
        }
    }

    private var introRow: some View {
        DomainIntroView(eyebrow: eyebrow, message: contextMessage)
            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20))
            .listRowBackground(Color(uiColor: .systemBackground))
            .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var attentionSection: some View {
        Section {
            if attentionTasks.isEmpty {
                Text(isWork ? "No immediate pressure. Your focus is clear." : "Nothing needs your attention right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    .listRowInsets(Self.rowInsets)
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .listRowSeparator(.hidden)
            } else {
                ForEach(attentionTasks.prefix(3)) { task in
                    taskRow(task)
                }
                if attentionTasks.count > 3 {
                    NavigationLink {
                        TaskCollectionView(
                            title: "Needs attention",
                            tasks: attentionTasks,
                            domainName: domainName
                        )
                    } label: {
                        Text("View all \(attentionTasks.count) items")
                            .font(.subheadline.weight(.semibold))
                    }
                    .listRowInsets(Self.rowInsets)
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            EditorialSectionHeader(
                title: "Needs attention",
                subtitle: isWork ? "Overdue and due today" : "What needs care today"
            )
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        if !upcomingGroups.isEmpty {
            Section {
                ForEach(upcomingGroups.prefix(2)) { group in
                    ForEach(group.tasks.prefix(2)) { task in
                        taskRow(task)
                    }
                    if group.tasks.count > 2 {
                        NavigationLink {
                            TaskCollectionView(
                                title: group.title,
                                tasks: group.tasks,
                                domainName: domainName
                            )
                        } label: {
                            Text("See all \(group.tasks.count) on \(group.title)")
                                .font(.subheadline.weight(.semibold))
                        }
                        .listRowInsets(Self.rowInsets)
                        .listRowBackground(Color(uiColor: .systemBackground))
                        .listRowSeparator(.hidden)
                    }
                }
            } header: {
                EditorialSectionHeader(title: "Coming up", subtitle: "The days just ahead")
            }
        }
    }

    @ViewBuilder
    private var listsSection: some View {
        Section {
            if domainLists.isEmpty {
                Text("No lists yet. Everything lives in \(displayName) until you need more structure.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    .listRowInsets(Self.rowInsets)
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .listRowSeparator(.hidden)
            } else {
                ForEach(domainLists) { list in
                    NavigationLink {
                        ListTasksView(list: list, domainName: domainName)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.name)
                                    .font(.body.weight(.semibold))
                                Text("\(openTasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }.count) open")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(Self.rowInsets)
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            EditorialSectionHeader(
                title: "Organized by list",
                subtitle: isWork ? "Projects and responsibilities" : "Areas of life"
            )
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        Section {
            if completedTasks.isEmpty {
                Text(isWork ? "Completed work will appear here." : "Finished tasks will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    .listRowInsets(Self.rowInsets)
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .listRowSeparator(.hidden)
            } else {
                ForEach(completedTasks.prefix(2)) { task in
                    taskRow(task)
                }
                if completedTasks.count > 2 {
                    NavigationLink {
                        TaskCollectionView(
                            title: "Completed",
                            tasks: completedTasks,
                            domainName: domainName
                        )
                    } label: {
                        Text("See all \(completedTasks.count) completed")
                            .font(.subheadline.weight(.semibold))
                    }
                    .listRowInsets(Self.rowInsets)
                    .listRowBackground(Color(uiColor: .systemBackground))
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            EditorialSectionHeader(
                title: "Recently completed",
                subtitle: isWork ? "Progress, without the noise" : "What you have already handled"
            )
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        TaskRowView(task: task)
            .taskActions(
                task: task,
                onToggle: { actions.toggleCompletion(for: task, in: modelContext) },
                onDelete: { actions.delete(task, in: modelContext) }
            )
            .listRowInsets(Self.rowInsets)
            .listRowBackground(Color(uiColor: .systemBackground))
            .listRowSeparator(.hidden)
    }

    private static let rowInsets = EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
}

private struct UpcomingGroup: Identifiable {
    let date: Date
    let tasks: [TaskItem]

    var id: Date { date }

    var title: String {
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

struct TaskCollectionView: View {
    let title: String
    let tasks: [TaskItem]
    let domainName: String
    var showsDomain = false

    @Environment(\.modelContext) private var modelContext
    @State private var actions = TaskActionsViewModel()

    var body: some View {
        List {
            if tasks.isEmpty {
                Text("Nothing here yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(tasks) { task in
                    TaskRowView(task: task, showsDomain: showsDomain)
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
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground).opacity(0.4))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.2), value: actions.revision)
    }
}

struct ListTasksView: View {
    let list: ReminderList
    let domainName: String

    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    @State private var actions = TaskActionsViewModel()

    private var listTasks: [TaskItem] {
        tasks
            .filter { $0.reminderList?.persistentModelID == list.persistentModelID }
            .sorted { $0.safeCreatedAt > $1.safeCreatedAt }
    }

    private var openTasks: [TaskItem] {
        listTasks.filter { $0.isCompleted != true }
    }

    private var completedTasks: [TaskItem] {
        listTasks.filter { $0.isCompleted == true }
    }

    var body: some View {
        List {
            Section {
                if openTasks.isEmpty {
                    Text("No open tasks in this list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(openTasks) { task in
                        TaskRowView(task: task)
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
                EditorialSectionHeader(title: "Tasks", subtitle: "Open responsibilities")
            }

            if !completedTasks.isEmpty {
                Section {
                    ForEach(completedTasks) { task in
                        TaskRowView(task: task)
                            .taskActions(
                                task: task,
                                onToggle: { actions.toggleCompletion(for: task, in: modelContext) },
                                onDelete: { actions.delete(task, in: modelContext) }
                            )
                            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                            .listRowBackground(Color(uiColor: .systemBackground))
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    EditorialSectionHeader(title: "Completed", subtitle: "Done in this list")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground).opacity(0.4))
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.2), value: actions.revision)
    }
}
