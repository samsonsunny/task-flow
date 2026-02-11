//
//  EmptyStateView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//



import SwiftUI

enum EmptyStateType {
    case noTasks
    case noOverdue
}

struct EmptyStateView: View {
    let type: EmptyStateType
    
    var body: some View {
        VStack(spacing: AppTheme.spacing.lg) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 56))
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
        case .noOverdue:
            return "clock"
        }
    }
    
    private var emptyStateTitle: String {
        switch type {
        case .noTasks:
            return "No Tasks"
        case .noOverdue:
            return "No Overdue Tasks"
        }
    }
    
    private var emptyStateMessage: String {
        switch type {
        case .noTasks:
            return "Create your first task to get started."
        case .noOverdue:
            return "Overdue tasks will appear here."
        }
    }
}

#Preview("No Tasks") {
    EmptyStateView(type: .noTasks)
}

#Preview("No Overdue Tasks") {
    EmptyStateView(type: .noOverdue)
}
