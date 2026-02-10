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
        HStack(alignment: .center, spacing: AppTheme.spacing.sm) {
            VStack(alignment: .leading, spacing: AppTheme.spacing.xs) {
                VStack(alignment: .leading, spacing: AppTheme.spacing.xxs) {
                    Text(task.safeTitle)
                        .font(AppTheme.fonts.headline)
                        .foregroundStyle(AppTheme.colors.text)
                        .strikethrough(task.safeIsCompleted)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Description hidden in list for minimal metadata
                }
                
                HStack(spacing: AppTheme.spacing.xs) {
                    if let dueDate = task.dueDate {
                        Label(
                            dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(AppTheme.fonts.caption)
                        .foregroundStyle(AppTheme.colors.secondaryText)
                    }

                    if let status = statusText {
                        Text("· \(status)")
                            .font(AppTheme.fonts.caption)
                            .foregroundStyle(statusColor)
                    }
                }
            }
            
            Spacer(minLength: AppTheme.spacing.xs)
            
            Image(systemName: "chevron.right")
                .font(AppTheme.fonts.caption2)
                .foregroundStyle(AppTheme.colors.secondaryText.opacity(0.5))
        }
        .padding(AppTheme.spacing.xs)
        .background(AppTheme.colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.large))
        .appShadow(AppTheme.shadows.elevation2)
        .contentShape(Rectangle())
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
            if task.safeIsCompleted { return AppTheme.colors.success.opacity(0.85) }
            if task.isOverdue { return AppTheme.colors.danger.opacity(0.85) }
            return AppTheme.colors.secondaryText
        case .standard, .none:
            if task.safeIsCompleted { return AppTheme.colors.secondaryText }
            if task.isOverdue { return AppTheme.colors.danger.opacity(0.85) }
            return AppTheme.colors.secondaryText
        }
    }
}
