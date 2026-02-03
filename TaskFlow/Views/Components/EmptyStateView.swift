//
//  EmptyStateView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//



import SwiftUI

struct EmptyStateView: View {
    let searchText: String
    let showCompleted: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Colors.secondaryText.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.text)
            
            Text(emptyStateMessage)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
//                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        } else if !showCompleted {
            return "checkmark.circle"
        } else {
            return "tray"
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results"
        } else if !showCompleted {
            return "All Done!"
        } else {
            return "No Tasks"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try searching with different keywords"
        } else if !showCompleted {
            return "All active tasks are completed.\nShow completed tasks to see them."
        } else {
            return "Create your first task to get started"
        }
    }
}

#Preview("No Tasks") {
    EmptyStateView(searchText: "", showCompleted: true)
}

#Preview("No Search Results") {
    EmptyStateView(searchText: "meeting", showCompleted: true)
}

#Preview("All Completed") {
    EmptyStateView(searchText: "", showCompleted: false)
}
 
