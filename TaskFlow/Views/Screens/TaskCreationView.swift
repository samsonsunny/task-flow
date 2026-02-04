//
//  TaskCreationView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct TaskCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)
    @State private var subtasks: [String] = []
    @State private var newSubtask = ""
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Task Title")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                            
                            TextField("Enter task title", text: $title)
                                .font(AppTheme.Typography.title)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Description")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                            
                            TextEditor(text: $description)
                                .font(AppTheme.Typography.body)
                                .frame(minHeight: 120)
                                .padding(AppTheme.Spacing.sm)
                                .background(AppTheme.Colors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .scrollContentBackground(.hidden)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Due Date")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                            
                            DatePicker(
                                "Select due date",
                                selection: $dueDate,
                                in: Date()...,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Subtasks (Optional)")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                            
                            ForEach(Array(subtasks.enumerated()), id: \.offset) { index, subtask in
                                HStack {
                                    Text(subtask)
                                        .font(AppTheme.Typography.body)
                                    Spacer()
                                    Button {
                                        subtasks.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.danger)
                                    }
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            HStack {
                                TextField("Add subtask", text: $newSubtask)
                                    .font(AppTheme.Typography.body)
                                    .textFieldStyle(.plain)
                                    .onSubmit(addSubtask)
                                
                                Button(action: addSubtask) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.Colors.primary)
                                }
                                .disabled(newSubtask.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createTask() }
                        .disabled(!isValid)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func addSubtask() {
        let trimmed = newSubtask.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        subtasks.append(trimmed)
        newSubtask = ""
    }
    
    private func createTask() {
        let task = TaskItem(
            taskTitle: title.trimmingCharacters(in: .whitespaces),
            taskDescription: description.trimmingCharacters(in: .whitespaces),
            dueDate: dueDate
        )
        
        var taskSubtasks: [Subtask] = []
        for subtaskTitle in subtasks {
            let subtask = Subtask(title: subtaskTitle)
            taskSubtasks.append(subtask)
        }
        task.subtasks = taskSubtasks
        
        modelContext.insert(task)
        dismiss()
    }
}
