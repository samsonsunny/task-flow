//
//  TaskRowView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    var isCompletedVisualState: Bool = false
    var onToggleCompletion: () -> Void

    @State private var chipScale: CGFloat = 1
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            completionButton

            Text(task.safeTitle)
                .font(AppTheme.fonts.body)
                .foregroundStyle(isCompletedVisualState ? AppTheme.colors.textSecondary : AppTheme.colors.textPrimary)
                .opacity(isCompletedVisualState ? 0.82 : 1.0)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, AppTheme.spacing.xs)
                .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)
        }
        .contentShape(Rectangle())
    }

    private var completionButton: some View {
        Button {
            animateChipTap()
            onToggleCompletion()
        } label: {
            ZStack {
                Circle()
                    .stroke(isCompletedVisualState ? AppTheme.colors.primaryAction : AppTheme.colors.border, lineWidth: 1.5)
                    .background(
                        Circle()
                            .fill(isCompletedVisualState ? AppTheme.colors.primaryAction : AppTheme.colors.surface)
                    )
                    .frame(width: 24, height: 24)
                    .animation(.easeInOut(duration: 0.18), value: isCompletedVisualState)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity(isCompletedVisualState ? 1 : 0)
                    .scaleEffect(isCompletedVisualState ? 1.0 : 0.85)
                    .animation(.easeInOut(duration: 0.14), value: isCompletedVisualState)
            }
            .scaleEffect(chipScale)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompletedVisualState ? "Mark active" : "Mark complete")
        .accessibilityHint(isCompletedVisualState ? "Reverts this task to pending" : "Marks this task as completed")
    }

    private func animateChipTap() {
        withAnimation(.easeOut(duration: 0.07)) {
            chipScale = 0.92
        }
        withAnimation(.spring(response: 0.12, dampingFraction: 0.7, blendDuration: 0)) {
            chipScale = 1.0
        }
    }

}
