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

        if arguments.contains(where: { $0.hasPrefix("UITEST_FIXED_NOW_") }) {
            NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
        }

        let fixedNow: Date = {
            for arg in arguments {
                let prefix = "UITEST_FIXED_NOW_"
                if arg.hasPrefix(prefix) {
                    let dateStr = String(arg.dropFirst(prefix.count))
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy_MM_dd"
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    return formatter.date(from: dateStr) ?? Date()
                }
            }
            return Date()
        }()

        if arguments.contains("UITEST_FIXTURE_UPCOMING_SECTIONS") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedUpcomingSectionsFixture(into: container, now: fixedNow)
            return container
        }

        if arguments.contains("UITEST_FIXTURE_UPCOMING_EMPTY") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedFarFutureUpcomingFixture(into: container, now: fixedNow)
            return container
        }

        if arguments.contains("UITEST_FIXTURE_REMINDER_HOME") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedReminderHomeFixture(into: container, now: fixedNow)
            return container
        }

        if arguments.contains("UITEST_FIXTURE_SUBTASKS_INLINE") {
            let container = TaskPreviewData.container()
            TaskPreviewData.seedSubtasksInlineFixture(into: container, now: fixedNow)
            return container
        }

        do {
            return try ModelContainer(
                for: Schema(versionedSchema: TaskFlowSchemaV9.self)
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

