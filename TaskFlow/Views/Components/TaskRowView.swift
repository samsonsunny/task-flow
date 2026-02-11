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
        case none
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing.sm) {
            VStack(alignment: .leading, spacing: AppTheme.spacing.xs) {
                VStack(alignment: .leading, spacing: AppTheme.spacing.xxs) {
                    Text(task.safeTitle)
                        .font(AppTheme.fonts.headline)
                        .foregroundStyle(AppTheme.colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppTheme.spacing.xs)
        .background(AppTheme.colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.large))
        .appShadow(AppTheme.shadows.elevation2)
        .contentShape(Rectangle())
    }

}
