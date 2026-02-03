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
    
    @State private var searchText = ""
    @State private var showCompleted = true
    @State private var showingCreateTask = false
    
    var filteredTasks: [TaskItem] {
        tasks.filter { task in
            let matchesSearch = searchText.isEmpty || 
                task.safeTitle.localizedCaseInsensitiveContains(searchText) ||
                task.safeDescription.localizedCaseInsensitiveContains(searchText)
            let matchesCompletionFilter = showCompleted || !task.safeIsCompleted
            return matchesSearch && matchesCompletionFilter
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                if filteredTasks.isEmpty {
                    EmptyStateView(searchText: searchText, showCompleted: showCompleted)
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            NavigationLink(value: task) {
                                TaskRowView(task: task)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Spacing.sm,
                                leading: AppTheme.Spacing.md,
                                bottom: AppTheme.Spacing.sm,
                                trailing: AppTheme.Spacing.md
                            ))
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Toggle("Show Completed", isOn: $showCompleted)
                        
                        Divider()
                        
                        Button {
                            showingCreateTask = true
                        } label: {
                            Label("New Task", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
            }
            .navigationDestination(for: TaskItem.self) { task in
                TaskDetailView(task: task)
            }
            .sheet(isPresented: $showingCreateTask) {
                TaskCreationView()
            }
            .refreshable {
                // Pull to refresh - triggers SwiftData to sync with iCloud
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewTask)) { _ in
            showingCreateTask = true
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTasks[index])
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
        .modelContainer(for: [TaskItem.self, Subtask.self, DailyLogEntry.self], inMemory: true)
}
