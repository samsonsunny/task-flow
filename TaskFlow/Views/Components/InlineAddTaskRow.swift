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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if !isFocused {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                
                TextField("Add a task...", text: $title, axis: .vertical)
                    .font(.headline)
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
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                    .buttonStyle(.plain)
                    
                    Button("Add") {
                        createTask()
                    }
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.Colors.primary.opacity(isFocused ? 0.12 : 0), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
            
            if isFocused && !title.trimmingCharacters(in: .whitespaces).isEmpty && !dueDateEnabled {
                Button {
                    dueDateEnabled = true
                    showDatePicker = false
                    if selectedSuggestion == nil {
                        applySuggestion(.today)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                        Text("Add due date")
                            .font(AppTheme.Typography.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            
            if dueDateEnabled {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(DueSuggestion.allCases) { suggestion in
                                Button(suggestion.rawValue) {
                                    applySuggestion(suggestion)
                                }
                                .font(AppTheme.Typography.caption.weight(.medium))
                                .foregroundStyle(selectedSuggestion == suggestion ? .white : AppTheme.Colors.primary)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedSuggestion == suggestion ? AppTheme.Colors.primary : AppTheme.Colors.background)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                                )
                                .frame(height: 34)
                            }
                        }
                    }
                    
                    HStack(spacing: AppTheme.Spacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption.weight(.semibold))
                            Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(AppTheme.Typography.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppTheme.Colors.text)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, 8)
                        .background(AppTheme.Colors.secondaryBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.Colors.secondaryText.opacity(0.12), lineWidth: 1)
                        )
                        
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.primary)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.Colors.secondaryBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            dueDateEnabled = false
                            selectedSuggestion = nil
                            showDatePicker = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.Colors.secondaryBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.Colors.secondaryText.opacity(0.12), lineWidth: 1)
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
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.bottom, AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground.ignoresSafeArea())
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
