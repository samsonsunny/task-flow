//
//  TaskRowView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.safeTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .strikethrough(task.safeIsCompleted)
                    
                    if !task.safeDescription.isEmpty {
                        Text(task.safeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                TaskStatusBadge(task: task)
            }
            
            HStack {
                Label(
                    task.safeDueDate.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundStyle(task.isOverdue ? AppTheme.Colors.danger : .secondary)
                
                if !task.safeSubtasks.isEmpty {
                    Spacer()
                    Label(
                        "\(task.completedSubtasksCount)/\(task.safeSubtasks.count)",
                        systemImage: "checklist"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            if !task.safeSubtasks.isEmpty {
                ProgressView(value: task.subtaskProgress)
                    .tint(task.safeIsCompleted ? .green : .accentColor)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

