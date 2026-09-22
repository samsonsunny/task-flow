import Foundation
import SwiftData

@MainActor
func backfillSortOrdersIfNeeded(in modelContext: ModelContext) {
    let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.sortOrder == nil })
    let missing = (try? modelContext.fetch(descriptor)) ?? []
    guard !missing.isEmpty else { return }

    let missingListIDs = Set(missing.compactMap { $0.reminderList?.persistentModelID })

    for listID in missingListIDs {
        let listDescriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.reminderList?.persistentModelID == listID })
        let tasksInList = (try? modelContext.fetch(listDescriptor)) ?? []
        guard !tasksInList.isEmpty else { continue }

        let maxExisting = tasksInList.compactMap { $0.sortOrder }.max() ?? -1
        let pending = tasksInList
            .filter { $0.sortOrder == nil }
            .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }

        for (index, task) in pending.enumerated() {
            task.sortOrder = maxExisting + 1 + index
        }
    }

    try? modelContext.save()
}

@MainActor
func backfillListSortOrdersIfNeeded(in modelContext: ModelContext) {
    let descriptor = FetchDescriptor<ReminderList>()
    let allLists = (try? modelContext.fetch(descriptor)) ?? []

    let unassigned = allLists.filter { $0.sortOrder == nil }
    guard !unassigned.isEmpty else { return }

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

    try? modelContext.save()
}