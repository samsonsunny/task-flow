//
//  ContentView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

// ==========================================
// MARK: - Content View
// File: App/ContentView.swift
// ==========================================

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @AppStorage("taskflow.onboarding.complete") private var hasOnboarded = false
    @AppStorage("taskflow.notifications.enabled") private var notificationsEnabled = false
    @AppStorage("dailyReviewEnabled") private var dailyReviewEnabled = true
    @AppStorage("taskflow.sampletask.created") private var sampleTaskCreated = false
    @State private var focusAddOnAppear = false
    
    var body: some View {
        if hasOnboarded {
            TaskListView(shouldFocusOnAppear: focusAddOnAppear)
                .task {
                    if notificationsEnabled && dailyReviewEnabled {
                        NotificationManager.shared.scheduleDailyReview()
                    }
                }
                .onAppear {
                    if focusAddOnAppear {
                        focusAddOnAppear = false
                    }
                }
        } else {
            OnboardingView { shouldFocusAdd in
                hasOnboarded = true
                focusAddOnAppear = shouldFocusAdd
                seedSampleTaskIfNeeded()
            }
        }
    }

    private func seedSampleTaskIfNeeded() {
        guard !sampleTaskCreated, tasks.isEmpty else { return }
        let dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let sample = TaskItem(
            taskTitle: "Plan the week",
            taskDescription: "Block time for your top 3 priorities.",
            dueDate: dueDate
        )
        modelContext.insert(sample)
        sampleTaskCreated = true
    }
}

#Preview("Empty State") {
    ContentView()
        .modelContainer(for: [TaskItem.self, DailyLogEntry.self], inMemory: true)
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedTaskList(into: container)
    return ContentView()
        .modelContainer(container)
}
