//
//  TaskRowView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    var isSelected: Bool = false
    var statusStyle: StatusStyle = .standard

    enum StatusStyle {
        case standard
        case none
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing.sm) {
            VStack(alignment: .leading, spacing: AppTheme.spacing.xs) {
                VStack(alignment: .leading, spacing: AppTheme.spacing.xxs) {
                    Text(task.safeTitle)
                        .font(AppTheme.fonts.headline)
                        .foregroundStyle(AppTheme.colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.spacing.xs)
        .padding(.horizontal, AppTheme.spacing.xs)
        .background(
            isSelected ? AppTheme.colors.primaryAction.opacity(0.10) : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.medium))
        .contentShape(Rectangle())
    }

}
