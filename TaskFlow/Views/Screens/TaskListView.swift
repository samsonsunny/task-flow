//
//  TaskListView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    @FocusState private var addTaskFocused: Bool

    let shouldFocusOnAppear: Bool

    init(shouldFocusOnAppear: Bool = false) {
        self.shouldFocusOnAppear = shouldFocusOnAppear
    }
    
    private var incompleteTasks: [TaskItem] {
        tasks.filter { !$0.safeIsCompleted }
    }
    
    private var hasAnyTasks: Bool {
        !tasks.isEmpty
    }

    private enum TaskSection: String, CaseIterable, Identifiable {
        case today = "Today"
        case upcoming = "Upcoming"
        case later = "Later"

        var id: String { self.rawValue }
    }
    
    private var sectionedTasks: [(TaskSection, [TaskItem])] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let upcomingLimit = calendar.date(byAdding: .day, value: 7, to: todayStart) ?? todayStart
        
        var buckets: [TaskSection: [TaskItem]] = [
            .today: [],
            .upcoming: [],
            .later: []
        ]
        
        for task in incompleteTasks {
            guard let due = task.dueDate else {
                buckets[.today, default: []].append(task)
                continue
            }
            if due < todayStart {
                // Overdue handled separately
                continue
            } else if calendar.isDateInToday(due) {
                buckets[.today, default: []].append(task)
            } else if due <= upcomingLimit {
                buckets[.upcoming, default: []].append(task)
            } else {
                buckets[.later, default: []].append(task)
            }
        }
        
        return ([TaskSection.today, TaskSection.upcoming, TaskSection.later]).compactMap { section in
            guard let items = buckets[section], !items.isEmpty else { return nil }
            return (section, items)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing.md) {
                        if incompleteTasks.isEmpty {
                            EmptyStateView(type: hasAnyTasks ? .allDone : .noTasks)
                        } else {
                            ForEach(sectionedTasks, id: \.0) { section, items in
                                Text(section.rawValue)
                                    .font(AppTheme.fonts.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.colors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, AppTheme.spacing.sm)
                                
                                ForEach(items) { task in
                                    taskRow(task)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing.lg)
                    .padding(.top, AppTheme.spacing.md)
                    .padding(.bottom, AppTheme.spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        addTaskFocused = false
                    }
                )
                .animation(.easeInOut, value: incompleteTasks.count)
            }
            .navigationTitle("Tasks")
            .onAppear {
                if shouldFocusOnAppear {
                    DispatchQueue.main.async {
                        addTaskFocused = true
                    }
                }
                normalizeMissingDueDates()
            }
            .navigationDestination(for: TaskItem.self) { task in
                TaskDetailView(task: task)
            }
            .safeAreaInset(edge: .bottom) {
                InlineAddTaskRow(isFocused: $addTaskFocused, onCreate: createInlineTask)
            }
        }
    }
    
    private func taskRow(_ task: TaskItem) -> some View {
        NavigationLink(value: task) {
            TaskRowView(task: task)
        }
        .buttonStyle(.plain)
    }
    
    private func createInlineTask(title: String, dueDate: Date) {
        let task = TaskItem(
            taskTitle: title,
            dueDate: dueDate
        )
        modelContext.insert(task)
    }

    private func normalizeMissingDueDates() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        var didUpdate = false
        for task in tasks where task.dueDate == nil {
            task.dueDate = todayStart
            didUpdate = true
        }
        if didUpdate {
            try? modelContext.save()
        }
    }
    
}



#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedTaskList(into: container)
    return TaskListView()
        .modelContainer(container)
}

#Preview("Empty State") {
    TaskListView()
        .modelContainer(for: [TaskItem.self], inMemory: true)
}
