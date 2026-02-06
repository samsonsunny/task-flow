//
//  TaskFlowApp.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//


// ==========================================
// MARK: - App Entry Point
// File: TaskFlowApp.swift
// ==========================================
import SwiftUI
import SwiftData

@main
struct TaskFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            DailyLogEntry.self
        ])
        
        // Enable iCloud sync with automatic CloudKit database
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // 🔑 KEY: Enables iCloud sync
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        
    }
}
