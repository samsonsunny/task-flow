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
    @AppStorage("taskflow.notifications.enabled") private var notificationsEnabled = false
    @AppStorage("dailyReviewEnabled") private var dailyReviewEnabled = true
    @State private var focusAddOnAppear = false
    
    var body: some View {
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
    }
}

#Preview("Empty State") {
    ContentView()
        .modelContainer(for: [TaskItem.self], inMemory: true)
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedTaskList(into: container)
    return ContentView()
        .modelContainer(container)
}
