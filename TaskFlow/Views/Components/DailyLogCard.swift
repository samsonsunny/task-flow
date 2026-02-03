//
//  DailyLogCard.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


import SwiftUI
import SwiftData

struct DailyLogCard: View {
    let entry: DailyLogEntry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Label(
                    entry.safeTimestamp.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "clock"
                )
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.danger.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            Text(entry.safeNote)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}