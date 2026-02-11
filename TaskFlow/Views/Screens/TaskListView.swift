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
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    
    @State private var isPresentingQuickAdd = false

    private let floatingButtonSize: CGFloat = 56
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    Group {
                    if tasks.isEmpty {
                        EmptyStateView(type: .noTasks)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(tasks) { task in
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
                .animation(.easeInOut, value: tasks.count)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isPresentingQuickAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(AppTheme.fonts.title2.weight(.semibold))
                                .foregroundStyle(AppTheme.colors.background)
                                .frame(width: floatingButtonSize, height: floatingButtonSize)
                                .background(AppTheme.colors.primary)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, AppTheme.spacing.lg)
                        .padding(.bottom, AppTheme.spacing.lg)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Tasks")
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

}

private struct QuickAddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    @FocusState private var titleFocused: Bool
    
    let onCreate: (_ title: String, _ dueDate: Date) -> Void
    
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.lg) {
            Text("Task title")
                .font(AppTheme.fonts.caption)
                .foregroundStyle(AppTheme.colors.secondaryText)

            TextField("Task title", text: $title, axis: .vertical)
                .font(AppTheme.fonts.headline)
                .textFieldStyle(.plain)
                .lineLimit(3)
                .focused($titleFocused)
                .padding(.vertical, AppTheme.spacing.sm)
                .padding(.horizontal, AppTheme.spacing.md)
                .background(AppTheme.colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.medium))
            
            Spacer()
            
            HStack {
                Spacer()
                Button {
                    onCreate(trimmedTitle, dueDate)
                    dismiss()
                } label: {
                    Text("Add")
                        .font(AppTheme.fonts.body.weight(.semibold))
                        .foregroundStyle(AppTheme.colors.background)
                        .padding(.horizontal, AppTheme.spacing.lg)
                        .padding(.vertical, AppTheme.spacing.sm)
                        .background(trimmedTitle.isEmpty ? AppTheme.colors.secondaryText.opacity(0.3) : AppTheme.colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.medium))
                }
                .disabled(trimmedTitle.isEmpty)
            }
        }
        .padding(.horizontal, AppTheme.spacing.lg)
        .padding(.top, AppTheme.spacing.md)
        .padding(.bottom, AppTheme.spacing.lg)
        .presentationDetents([.height(240)])
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                titleFocused = true
            }
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
