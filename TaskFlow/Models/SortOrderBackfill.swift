import Foundation
import SwiftData

@MainActor
func backfillSortOrdersIfNeeded(in modelContext: ModelContext) {
    let key = "didBackfillSortOrderV3"
    guard !UserDefaults.standard.bool(forKey: key) else { return }

    do {
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = try modelContext.fetch(descriptor)

        let grouped = Dictionary(grouping: allTasks.filter { $0.reminderList != nil }) { $0.reminderList?.persistentModelID }

        for (_, tasks) in grouped {
            let sorted = tasks.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            var previous: String?
            for task in sorted {
                task.sortOrder = midpoint(between: previous, and: nil)
                previous = task.sortOrder
            }
        }

        try modelContext.save()
        UserDefaults.standard.set(true, forKey: key)
    } catch {
        print("sortOrder backfill failed: \(error)")
    }
}
