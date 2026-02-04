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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.sm) {
                            if incompleteTasks.isEmpty {
                                emptyState
                            } else {
                                ForEach(incompleteTasks) { task in
                                    NavigationLink(value: task) {
                                        TaskRowView(task: task)
                                    }
                                    .buttonStyle(.plain)
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
    
    private var completedTasksLink: some View {
        NavigationLink {
            CompletedTasksView()
        } label: {
            HStack {
                Text("Completed Tasks")
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
