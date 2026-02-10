//
//  EmptyStateView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//



import SwiftUI

enum EmptyStateType {
    case noTasks
    case allDone
    case noCompleted
    case noOverdue
}

struct EmptyStateView: View {
    let type: EmptyStateType
    
    var body: some View {
        VStack(spacing: AppTheme.spacing.lg) {
            Image(systemName: emptyStateIcon)
                .font(AppTheme.fonts.extraLargeIcon)
                .foregroundStyle(AppTheme.colors.secondaryText.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(AppTheme.fonts.title)
                .foregroundStyle(AppTheme.colors.text)
            
            Text(emptyStateMessage)
                .font(AppTheme.fonts.body)
                .foregroundStyle(AppTheme.colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateIcon: String {
        switch type {
        case .noTasks:
            return "tray"
        case .allDone:
            return "checkmark.circle"
        case .noCompleted:
            return "checkmark.circle"
        case .noOverdue:
            return "clock"
        }
    }
    
    private var emptyStateTitle: String {
        switch type {
        case .noTasks:
            return "No Tasks"
        case .allDone:
            return "All Done!"
        case .noCompleted:
            return "No Completed Tasks"
        case .noOverdue:
            return "No Overdue Tasks"
        }
    }
    
    private var emptyStateMessage: String {
        switch type {
        case .noTasks:
            return "Create your first task to get started."
        case .allDone:
            return "You have no active tasks."
        case .noCompleted:
            return "Completed tasks will appear here."
        case .noOverdue:
            return "Overdue tasks will appear here."
        }
    }
}

#Preview("No Tasks") {
    EmptyStateView(type: .noTasks)
}

#Preview("All Done") {
    EmptyStateView(type: .allDone)
}

#Preview("No Completed Tasks") {
    EmptyStateView(type: .noCompleted)
}

#Preview("No Overdue Tasks") {
    EmptyStateView(type: .noOverdue)
}
