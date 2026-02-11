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
    
    @State private var isPresentingQuickAdd = false
    
    private let floatingButtonSize: CGFloat = 56
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing.md) {
                        if tasks.isEmpty {
                            EmptyStateView(type: .noTasks)
                        } else {
                            ForEach(tasks) { task in
                                taskRow(task)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing.lg)
                    .padding(.top, AppTheme.spacing.md)
                    .padding(.bottom, AppTheme.spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut, value: tasks.count)
            }
            .navigationTitle("Tasks")
            .onAppear {
                normalizeMissingDueDates()
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    isPresentingQuickAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(AppTheme.fonts.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.colors.background)
                        .frame(width: floatingButtonSize, height: floatingButtonSize)
                        .background(AppTheme.colors.primary)
                        .clipShape(Circle())
                        .appShadow(AppTheme.shadows.elevation2)
                }
                .padding(.trailing, AppTheme.spacing.lg)
                .padding(.bottom, AppTheme.spacing.lg)
            }
            .sheet(isPresented: $isPresentingQuickAdd) {
                QuickAddTaskSheet(onCreate: createTask)
            }
        }
    }
    
    private func taskRow(_ task: TaskItem) -> some View {
        TaskRowView(task: task)
    }
    
    private func createTask(title: String, dueDate: Date) {
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

private struct QuickAddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    
    let onCreate: (_ title: String, _ dueDate: Date) -> Void
    
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.lg) {
            Text("New task")
                .font(AppTheme.fonts.caption)
                .foregroundStyle(AppTheme.colors.secondaryText)
            
            TextField("Task title", text: $title, axis: .vertical)
                .font(AppTheme.fonts.headline)
                .textFieldStyle(.plain)
                .lineLimit(3)
                .padding(.bottom, AppTheme.spacing.sm)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(AppTheme.colors.secondaryText.opacity(0.2)),
                    alignment: .bottom
                )
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(AppTheme.colors.secondaryText)
                
                Spacer()
                
                Button("Add") {
                    onCreate(trimmedTitle, dueDate)
                    dismiss()
                }
                .disabled(trimmedTitle.isEmpty)
            }
            .font(AppTheme.fonts.body.weight(.semibold))
        }
        .padding(AppTheme.spacing.lg)
        .presentationDetents([.height(240), .medium, .large])
        .presentationDragIndicator(.visible)
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
