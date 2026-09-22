import SwiftData

@MainActor
func reconcileInboxLists(in modelContext: ModelContext) {
    let fetchDescriptor = FetchDescriptor<ReminderList>()
    guard let allLists = try? modelContext.fetch(fetchDescriptor) else { return }
    let inboxes = allLists.filter { $0.name == ReminderDefaults.defaultListName }
    guard inboxes.count > 1 else { return }

    let keeper = inboxes[0]
    for extra in inboxes.dropFirst() {
        let tasks = extra.remindersArray.filter { $0.reminderList?.persistentModelID == extra.persistentModelID }
        for task in tasks {
            task.reminderList = keeper
        }
        modelContext.delete(extra)
    }
    try? modelContext.save()
}