//
//  TaskListView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData
import UIKit

struct TaskListView: View {
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    
    @State private var showingCreateTask = false
    
    private var incompleteTasks: [TaskItem] {
        tasks.filter { !$0.safeIsCompleted }
    }
    
    private var completedTasksCount: Int {
        tasks.filter { $0.safeIsCompleted }.count
    }
    
    private var hasCompletedTasks: Bool {
        completedTasksCount > 0
    }
    
    private var hasAnyTasks: Bool {
        !tasks.isEmpty
    }

    private enum TaskSection: String, CaseIterable {
        case today = "Today"
        case upcoming = "Upcoming"
        case later = "Later"
    }
    
    private var overdueTasks: [TaskItem] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        return incompleteTasks.filter { $0.safeDueDate < todayStart }
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
            let due = task.safeDueDate
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
        
        return TaskSection.allCases.compactMap { section in
            guard let items = buckets[section], !items.isEmpty else { return nil }
            return (section, items)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            if incompleteTasks.isEmpty {
                                emptyState
                            } else {
                                if !overdueTasks.isEmpty {
                                    overdueTasksLink
                                }
                                
                                ForEach(sectionedTasks, id: \.0) { section, items in
                                    Text(section.rawValue)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, AppTheme.Spacing.sm)
                                    
                                    ForEach(items) { task in
                                        taskRow(task)
                                    }
                                }
                                
                                if hasCompletedTasks {
                                    completedTasksLink
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.top, AppTheme.Spacing.sm)
                        .padding(.bottom, AppTheme.Spacing.lg)
                    }
                }
                .animation(.easeInOut, value: incompleteTasks.count)
                .animation(.easeInOut, value: completedTasksCount)
                
                addTaskButton
            }
            .navigationTitle("Tasks")
            .navigationDestination(for: TaskItem.self) { task in
                TaskDetailView(task: task)
            }
            .sheet(isPresented: $showingCreateTask) {
                TaskCreationView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewTask)) { _ in
            showingCreateTask = true
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: hasAnyTasks ? "checkmark.circle" : "tray")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.Colors.secondaryText.opacity(0.5))
            
            Text(hasAnyTasks ? "All Done!" : "No Tasks")
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.text)
            
            Text(hasAnyTasks ? "You have no active tasks." : "Create your first task to get started.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.Spacing.lg)
    }

    private var overdueTasksLink: some View {
        NavigationLink {
            OverdueTasksView()
        } label: {
            HStack {
                Text("Overdue")
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.text)
                Spacer()
                Text("\(overdueTasks.count)")
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.background)
                    .clipShape(Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private var completedTasksLink: some View {
        NavigationLink {
            CompletedTasksView()
        } label: {
            HStack {
                Text("Completed")
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.text)
                Spacer()
                Text("\(completedTasksCount)")
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.background)
                    .clipShape(Capsule())
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private func taskRow(_ task: TaskItem) -> some View {
        NavigationLink(value: task) {
            TaskRowView(task: task)
        }
        .buttonStyle(.plain)
    }
    
    private var addTaskButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    triggerHaptic()
                    showingCreateTask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(AppTheme.Colors.primary)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
                }
                .buttonStyle(FloatingActionButtonStyle())
                .accessibilityLabel("Add Task")
                .padding(.trailing, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg + 6)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
}

private struct FloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct CompletedTasksView: View {
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted == true }, sort: \TaskItem.dueDate) private var completedTasks: [TaskItem]
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            if completedTasks.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.Colors.secondaryText.opacity(0.5))
                    
                    Text("No Completed Tasks")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.text)
                    
                    Text("Completed tasks will appear here.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppTheme.Spacing.lg)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(completedTasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                TaskRowView(task: task)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
        }
        .navigationTitle("Completed")
    }
}

private struct OverdueTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<TaskItem> { $0.isCompleted == false }, sort: \TaskItem.dueDate) private var activeTasks: [TaskItem]
    
    private var overdueTasks: [TaskItem] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        return activeTasks.filter { $0.safeDueDate < todayStart }
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            if overdueTasks.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "clock")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.Colors.secondaryText.opacity(0.5))
                    
                    Text("No Overdue Tasks")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.text)
                    
                    Text("Overdue tasks will appear here.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppTheme.Spacing.lg)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(overdueTasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                TaskRowView(task: task)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Move to Today") { reschedule(task, daysFromToday: 0) }
                                Button("Move to Tomorrow") { reschedule(task, daysFromToday: 1) }
                                Button("Move to Next Week") { reschedule(task, daysFromToday: 7) }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
        }
        .navigationTitle("Overdue")
    }
    
    private func reschedule(_ task: TaskItem, daysFromToday: Int) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let newDate = calendar.date(byAdding: .day, value: daysFromToday, to: todayStart) ?? todayStart
        task.dueDate = newDate
        modelContext.insert(task)
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
        .modelContainer(for: [TaskItem.self, Subtask.self, DailyLogEntry.self], inMemory: true)
}
