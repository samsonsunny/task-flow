//
//  ContentView.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

// ==========================================
// MARK: - Content View
// File: Views/ContentView.swift
// ==========================================

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
let schema = Schema([
    TaskItem.self,
    Subtask.self,
    DailyLogEntry.self
])

#Preview("Empty State") {
    ContentView()
        .modelContainer(for: [TaskItem.self, Subtask.self, DailyLogEntry.self], inMemory: true)
}

#Preview("With Tasks") {
    let container = try! ModelContainer(
        for: TaskItem.self, Subtask.self, DailyLogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    // Add sample data...
    
    return ContentView()
        .modelContainer(container)
}
