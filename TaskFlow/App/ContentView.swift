import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MainTabView()
            .onAppear {
                migrateOrphanedTasks()
                backfillSortOrdersIfNeeded(in: modelContext)
            }
    }

    private func migrateOrphanedTasks() {
        let key = "did_migrate_orphaned_tasks_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.reminderList == nil }
        )
        guard let orphans = try? modelContext.fetch(descriptor), !orphans.isEmpty else { return }

        let defaultName = ReminderDefaults.defaultListName
        let listDescriptor = FetchDescriptor<ReminderList>(
            predicate: #Predicate { $0.name == defaultName }
        )
        let defaultList: ReminderList
        if let existing = try? modelContext.fetch(listDescriptor).first {
            defaultList = existing
        } else {
            let list = ReminderList(name: ReminderDefaults.defaultListName)
            modelContext.insert(list)
            defaultList = list
        }

        for task in orphans {
            task.reminderList = defaultList
        }
        try? modelContext.save()
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)
    return ContentView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return ContentView()
        .modelContainer(container)
        .environment(AppState())
}
