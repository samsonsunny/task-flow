//
//  InlineAddTaskRow.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

import SwiftUI
import UIKit

struct InlineAddTaskRow: View {
    @FocusState.Binding var isFocused: Bool
    let onCreate: (_ title: String, _ dueDate: Date?) -> Void
    
    @State private var title = ""
    @State private var dueDateEnabled = false
    @State private var dueDate = Date()
    @State private var selectedSuggestion: DueSuggestion? = nil
    @State private var showDatePicker = false
    
    private enum DueSuggestion: String, CaseIterable, Identifiable {
        case today = "Today"
        case tomorrow = "Tomorrow"
        case thisWeek = "This Week"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
            HStack(spacing: AppTheme.spacing.sm) {
                if !isFocused {
                    Image(systemName: "plus.circle.fill")
                        .font(AppTheme.fonts.title3)
                        .foregroundStyle(AppTheme.colors.primary)
                }
                
                TextField("Add a task...", text: $title, axis: .vertical)
                    .font(AppTheme.fonts.headline)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(handleSubmit)
                    .lineLimit(isFocused ? 3 : 1)
                    .fixedSize(horizontal: false, vertical: isFocused)
                    .multilineTextAlignment(.leading)
                    .onChange(of: title) { _, newValue in
                        if newValue.contains("\n") {
                            let sanitized = newValue.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
                            title = sanitized
                        }
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                clearDraft()
                            } else {
                                dueDateEnabled = false
                                showDatePicker = false
                            }
                        }
                    }
                
                if isFocused && !title.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        clearDraft()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(AppTheme.fonts.title3)
                            .foregroundStyle(AppTheme.colors.secondaryText)
                    }
                    .buttonStyle(.plain)
                    
                    Button("Add") {
                        createTask()
                    }
                    .font(AppTheme.fonts.body.weight(.semibold))
                    .foregroundStyle(AppTheme.colors.primary)
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.spacing.md)
            .background(AppTheme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radius.large)
                    .stroke(AppTheme.colors.primary.opacity(isFocused ? 0.12 : 0), lineWidth: 1)
            )
            .appShadow(AppTheme.shadows.elevationInlineAddTask)
            
            if isFocused && !title.trimmingCharacters(in: .whitespaces).isEmpty && !dueDateEnabled {
                Button {
                    dueDateEnabled = true
                    showDatePicker = false
                    if selectedSuggestion == nil {
                        applySuggestion(.today)
                    }
                } label: {
                    HStack(spacing: AppTheme.spacing.xs) {
                        Image(systemName: "calendar")
                            .font(AppTheme.fonts.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.colors.secondaryText)
                        Text("Add due date")
                            .font(AppTheme.fonts.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.colors.secondaryText)
                    }
                    .padding(.vertical, AppTheme.spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            
            if dueDateEnabled {
                VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.spacing.sm) {
                            ForEach(DueSuggestion.allCases) { suggestion in
                                Button(suggestion.rawValue) {
                                    applySuggestion(suggestion)
                                }
                                .font(AppTheme.fonts.caption.weight(.medium))
                                .foregroundStyle(selectedSuggestion == suggestion ? AppTheme.colors.text : AppTheme.colors.primary)
                                .padding(.horizontal, AppTheme.spacing.md)
                                .padding(.vertical, AppTheme.spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.radius.large)
                                        .fill(selectedSuggestion == suggestion ? AppTheme.colors.primary : AppTheme.colors.background)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radius.large)
                                        .stroke(AppTheme.colors.primary.opacity(0.2), lineWidth: 1)
                                )
                                .frame(height: 34)
                            }
                        }
                    }
                    
                    HStack(spacing: AppTheme.spacing.sm) {
                        HStack(spacing: AppTheme.spacing.xs) {
                            Image(systemName: "calendar")
                                .font(AppTheme.fonts.caption.weight(.semibold))
                            Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(AppTheme.fonts.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppTheme.colors.text)
                        .padding(.horizontal, AppTheme.spacing.md)
                        .padding(.vertical, AppTheme.spacing.xs)
                        .background(AppTheme.colors.secondaryBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.colors.secondaryText.opacity(0.12), lineWidth: 1)
                        )
                        
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .font(AppTheme.fonts.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.colors.primary)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.colors.secondaryBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.colors.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            dueDateEnabled = false
                            selectedSuggestion = nil
                            showDatePicker = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(AppTheme.fonts.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.colors.secondaryText)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.colors.secondaryBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.colors.secondaryText.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if showDatePicker {
                        DatePicker(
                            "Select due date",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .padding(AppTheme.spacing.sm)
                        .background(AppTheme.colors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.medium))
                    }
                }
                .padding(AppTheme.spacing.md)
                .background(AppTheme.colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.large))
                .appShadow(AppTheme.shadows.elevationInlineAddTask)
            }
        }
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.top, AppTheme.spacing.sm)
        .padding(.bottom, AppTheme.spacing.md)
        .background(AppTheme.colors.secondaryBackground.ignoresSafeArea())
    }
    
    private func handleSubmit() {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            clearDraft()
        } else {
            createTask()
            isFocused = false
        }
    }
    
    private func createTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        triggerHaptic()
        onCreate(trimmed, dueDateEnabled ? dueDate : nil)
        clearDraft()
    }
    
    private func clearDraft() {
        title = ""
        dueDateEnabled = false
        selectedSuggestion = nil
        showDatePicker = false
    }
    
    private func applySuggestion(_ suggestion: DueSuggestion) {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
        selectedSuggestion = suggestion
        dueDate = suggestionDate(suggestion)
    }
    
    private func suggestionDate(_ suggestion: DueSuggestion) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch suggestion {
        case .today:
            return today
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: today) ?? today
        case .thisWeek:
            let weekday = calendar.component(.weekday, from: today)
            let daysUntilEndOfWeek = max(0, 8 - weekday)
            return calendar.date(byAdding: .day, value: daysUntilEndOfWeek, to: today) ?? today
        }
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}
