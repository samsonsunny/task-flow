import Foundation
import SwiftData

struct ListSection: Identifiable {
    let id: String
    let title: String?
    let lists: [ReminderList]
}

func buildListSections(from lists: [ReminderList], excluding excludedListID: ReminderList.ID? = nil) -> [ListSection] {
    var remaining = lists
    if let excludedListID {
        remaining = remaining.filter { $0.persistentModelID != excludedListID }
    }

    var sections: [ListSection] = []

    if let defaultList = remaining.first(where: { $0.name == ReminderDefaults.defaultListName }) {
        sections.append(ListSection(id: "default", title: nil, lists: [defaultList]))
        remaining = remaining.filter { $0.persistentModelID != defaultList.persistentModelID }
    }

    let groupedByGroupID = Dictionary(grouping: remaining.filter { $0.group != nil }) { $0.group!.persistentModelID }
    let groupEntries: [(sortOrder: String, name: String, lists: [ReminderList])] = groupedByGroupID.compactMap { _, groupLists in
        guard let group = groupLists.first?.group else { return nil }
        return (group.sortOrder ?? "", group.name, groupLists)
    }
    let sortedGroupEntries = groupEntries.sorted { $0.sortOrder < $1.sortOrder }
    for entry in sortedGroupEntries {
        sections.append(ListSection(id: "group-\(entry.name)", title: entry.name, lists: entry.lists))
    }

    let ungrouped = remaining.filter { $0.group == nil }
    if !ungrouped.isEmpty {
        sections.append(ListSection(id: "ungrouped", title: nil, lists: ungrouped))
    }

    return sections
}
