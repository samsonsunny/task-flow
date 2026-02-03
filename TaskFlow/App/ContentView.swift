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
    var body: some View {
        #if os(iOS)
        TaskListView()
        #elseif os(macOS)
        NavigationSplitView {
            TaskListView()
        } detail: {
            Text("Select a task")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        #endif
    }
}

#Preview("Empty State") {
    ContentView()
        .modelContainer(for: [TaskItem.self, Subtask.self, DailyLogEntry.self], inMemory: true)
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedTaskList(into: container)
    return ContentView()
        .modelContainer(container)
}
