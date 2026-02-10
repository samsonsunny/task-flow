//
//  TaskStatusBadge.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI

struct TaskStatusBadge: View {
    let task: TaskItem
    
    var badgeColor: Color {
        if task.safeIsCompleted {
            return AppTheme.colors.success
        } else if task.isOverdue {
            return AppTheme.colors.danger
        } else {
            return AppTheme.colors.primary
        }
    }
    
    var badgeText: String {
        if task.safeIsCompleted {
            return "Done"
        } else if task.isOverdue {
            return "Overdue"
        } else {
            if task.dueDate == nil {
                return "No date"
            }
            let days = task.daysUntilDue
            return days > 0 ? "\(days)d left" : "Due"
        }
    }
    
    var body: some View {
        Text(badgeText)
            .font(AppTheme.fonts.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.colors.text)
            .padding(.horizontal, AppTheme.spacing.sm)
            .padding(.vertical, AppTheme.spacing.xs)
            .background(badgeColor)
            .clipShape(Capsule())
    }
}
