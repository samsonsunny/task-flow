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
import UserNotifications

@main
struct TaskFlowApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("UITEST_FIXTURE_UPCOMING_SECTIONS") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedUpcomingSectionsFixture(into: container, now: Date())
            return container
        }

        if arguments.contains("UITEST_FIXTURE_UPCOMING_EMPTY") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedFarFutureUpcomingFixture(into: container, now: Date())
            return container
        }

        if arguments.contains("UITEST_FIXTURE_REMINDER_HOME") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedReminderHomeFixture(into: container, now: Date())
            return container
        }

        if arguments.contains("UITEST_FIXTURE_SUBTASKS_INLINE") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedSubtasksInlineFixture(into: container, now: Date())
            return container
        }

        do {
            return try ModelContainer(
                for: Schema(versionedSchema: TaskFlowSchemaV8.self),
                migrationPlan: TaskFlowMigrationPlan.self
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    let context = ModelContext(sharedModelContainer)
                    NotificationService.shared.reschedulePendingOnLaunch(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                let context = ModelContext(sharedModelContainer)
                BadgeService.update(modelContext: context)
            }
        }
    }
}

