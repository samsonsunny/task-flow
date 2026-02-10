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
    @State private var focusAddOnAppear = false
    
    var body: some View {
        TaskListView(shouldFocusOnAppear: focusAddOnAppear)
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
