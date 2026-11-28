import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [ReminderListGroup]

    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max") {
                TodayView()
            }
            Tab("Work", systemImage: "briefcase") {
                DomainTasksView(domainName: "Work")
            }
            Tab("Home", image: "home") {
                DomainTasksView(domainName: "Personal")
            }
            Tab("More", systemImage: "ellipsis") {
                MoreView()
            }
        }
        .task {
            ensureDomains()
        }
    }

    private func ensureDomains() {
        var lockedGroups: [String: ReminderListGroup] = [:]

        for (index, name) in ["Work", "Personal"].enumerated() {
            let group: ReminderListGroup
            if let existing = groups.first(where: { $0.name == name }) {
                group = existing
            } else {
                group = ReminderListGroup(name: name, sortOrder: String(index))
                modelContext.insert(group)
            }
            lockedGroups[name] = group

            if !group.listsArray.contains(where: { $0.name == "Inbox" }) {
                let inbox = ReminderList(name: "Inbox", sortOrder: "0", group: group)
                group.lists = (group.lists ?? []) + [inbox]
            }
        }

        guard let work = lockedGroups["Work"] else { return }
        let extraGroups = groups.filter { $0.name != "Work" && $0.name != "Personal" }
        for group in extraGroups {
            for list in group.listsArray {
                list.group = work
            }
            modelContext.delete(group)
        }

        try? modelContext.save()
    }
}
