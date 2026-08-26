import Foundation
import SwiftData

@MainActor
func backfillSortOrdersIfNeeded(in modelContext: ModelContext) {
    let key = "didBackfillSortOrderV4"
    guard !UserDefaults.standard.bool(forKey: key) else { return }

    do {
        let descriptor = FetchDescriptor<TaskItem>()
        let allTasks = try modelContext.fetch(descriptor)

        let grouped = Dictionary(grouping: allTasks.filter { $0.reminderList != nil }) { $0.reminderList?.persistentModelID }

        for (_, tasks) in grouped {
            let sorted = tasks.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            recalculateSortOrders(for: sorted)
        }

        try modelContext.save()
        UserDefaults.standard.set(true, forKey: key)
    } catch {
    }
}

@MainActor
func backfillListSortOrdersIfNeeded(in modelContext: ModelContext) {
    let key = "didBackfillListSortOrderV3"
    guard !UserDefaults.standard.bool(forKey: key) else { return }

    do {
        let descriptor = FetchDescriptor<ReminderList>()
        let allLists = try modelContext.fetch(descriptor)

        let unassigned = allLists.filter { $0.sortOrder == nil }
        guard !unassigned.isEmpty else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        let sorted = allLists.sorted { lhs, rhs in
            if lhs.name == ReminderDefaults.defaultListName { return true }
            if rhs.name == ReminderDefaults.defaultListName { return false }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }

        let assigned = sorted.filter { $0.sortOrder != nil }
        let needsOrder = sorted.filter { $0.sortOrder == nil }

        let lastAssigned = assigned.compactMap { $0.sortOrder }.sorted().last
        var previous = lastAssigned
        for list in needsOrder {
            list.sortOrder = midpoint(between: previous, and: nil)
            previous = list.sortOrder
        }

        try modelContext.save()
        UserDefaults.standard.set(true, forKey: key)
    } catch {
    }
}
