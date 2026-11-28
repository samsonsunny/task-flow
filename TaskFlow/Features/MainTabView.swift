import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [ReminderListGroup]

    var body: some View {
        TabView {
            TabSection {
                Tab("Home", image: "home") {
                    DomainTasksView(domainName: "Personal")
                }
                Tab("Work", systemImage: "briefcase") {
                    DomainTasksView(domainName: "Work")
                }
            }

            TabSection {
                Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    SearchView()
                }
            }
        }
        .task {
            ensureDomains()
        }
    }

    private func ensureDomains() {
        for (index, name) in ["Work", "Personal"].enumerated() {
            let group: ReminderListGroup
            if let existing = groups.first(where: { $0.name == name }) {
                group = existing
            } else {
                group = ReminderListGroup(name: name, sortOrder: String(index))
                modelContext.insert(group)
            }
            if !group.listsArray.contains(where: { $0.name == "Inbox" }) {
                let inbox = ReminderList(name: "Inbox", sortOrder: "0", group: group)
                group.lists = (group.lists ?? []) + [inbox]
            }
        }
        try? modelContext.save()
    }
}
