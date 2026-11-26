import SwiftUI
import SwiftData
import os

extension Logger {
    static let app = Logger(subsystem: "com.samson.wednesday", category: "App")
}

@main
struct TaskFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            let cloudConfig = ModelConfiguration(
                cloudKitDatabase: .private("iCloud.com.samson.wednesday")
            )
            return try ModelContainer(
                for: Schema(versionedSchema: TaskFlowSchemaV10.self),
                configurations: cloudConfig
            )
        } catch {
            Logger.app.error("CloudKit-backed ModelContainer failed; falling back to local-only: \(error, privacy: .public)")
            do {
                let localConfig = ModelConfiguration(cloudKitDatabase: .none)
                return try ModelContainer(
                    for: Schema(versionedSchema: TaskFlowSchemaV10.self),
                    configurations: localConfig
                )
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
