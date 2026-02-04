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
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.safeTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .strikethrough(task.safeIsCompleted)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Description hidden in list for minimal metadata
                }
                
                HStack(spacing: 8) {
                    Label(
                        task.safeDueDate.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let status = statusText {
                        Text("· \(status)")
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }
                    
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
            
            Spacer(minLength: 10)
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var statusText: String? {
        if task.safeIsCompleted { return "Done" }
        if task.isOverdue { return "Overdue" }
        return nil
    }
    
    private var statusColor: Color {
        if task.safeIsCompleted { return .secondary }
        if task.isOverdue { return AppTheme.Colors.danger.opacity(0.85) }
        return .secondary
    }
}
