//
//  SubtaskRow.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct SubtaskRow: View {
    @Bindable var subtask: Subtask
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                withAnimation {
                    subtask.completed = !(subtask.completed ?? false)
                }
            } label: {
                Image(systemName: subtask.safeCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(subtask.safeCompleted ? AppTheme.Colors.success : AppTheme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            
            Text(subtask.safeTitle)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.text)
                .strikethrough(subtask.safeCompleted)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppTheme.Colors.danger.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
