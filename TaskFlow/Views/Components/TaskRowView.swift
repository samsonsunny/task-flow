//
//  TaskRowView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    var statusStyle: StatusStyle = .standard

    enum StatusStyle {
        case standard
        case completedMetadata
        case none
    }
    
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
                    if let remindAt = task.remindAt {
                        Label(
                            remindAt.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "bell"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else if let dueDate = task.dueDate {
                        Label(
                            dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else {
                        Label("No date", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let status = statusText {
                        Text("· \(status)")
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }
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
        switch statusStyle {
        case .none:
            return nil
        case .standard:
            if task.safeIsCompleted { return "Done" }
            if task.isOverdue { return "Overdue" }
            return nil
        case .completedMetadata:
            if task.safeIsCompleted {
                if let completionDate = task.completionDate {
                    let dateText = completionDate.formatted(date: .abbreviated, time: .omitted)
                    return "Completed · \(dateText)"
                }
                return "Completed"
            }
            if task.isOverdue { return "Overdue" }
            return nil
        }
    }
    
    private var statusColor: Color {
        switch statusStyle {
        case .completedMetadata:
            if task.safeIsCompleted { return AppTheme.Colors.success.opacity(0.85) }
            if task.isOverdue { return AppTheme.Colors.danger.opacity(0.85) }
            return .secondary
        case .standard, .none:
            if task.safeIsCompleted { return .secondary }
            if task.isOverdue { return AppTheme.Colors.danger.opacity(0.85) }
            return .secondary
        }
    }
}
