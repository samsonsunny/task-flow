//
//  EmptyStateView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//



import SwiftUI

enum EmptyStateType {
    case noTasks
}

struct EmptyStateView: View {
    let type: EmptyStateType
    
    var body: some View {
        VStack(spacing: AppTheme.spacing.md) {
            Text(emptyStateTitle)
                .font(AppTheme.fonts.title)
                .foregroundStyle(AppTheme.colors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch type {
        case .noTasks:
            return "No Tasks"
        }
    }
}

#Preview("No Tasks") {
    EmptyStateView(type: .noTasks)
}
