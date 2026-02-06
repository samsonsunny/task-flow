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
            return AppTheme.Colors.success
        } else if task.isOverdue {
            return AppTheme.Colors.danger
        } else {
            return AppTheme.Colors.primary
        }
    }
    
    var badgeText: String {
        if task.safeIsCompleted {
            return "Done"
        } else if task.isOverdue {
            return "Overdue"
        } else {
            if task.reminderReferenceDate == nil {
                return "No date"
            }
            let days = task.daysUntilDue
            return days > 0 ? "\(days)d left" : "Due"
        }
    }
    
    var body: some View {
        Text(badgeText)
            .font(AppTheme.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(badgeColor)
            .clipShape(Capsule())
    }
}
