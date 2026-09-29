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

    let groupedByGroupID = Dictionary(grouping: remaining.filter { $0.group != nil }) { $0.group!.persistentModelID }
    let groupEntries: [(sortOrder: String, id: ReminderListGroup.ID, name: String, lists: [ReminderList])] = groupedByGroupID.compactMap { _, groupLists in
        guard let group = groupLists.first?.group else { return nil }
        return (group.sortOrder ?? "", group.persistentModelID, group.name, groupLists)
    }
    let sortedGroupEntries = groupEntries.sorted { $0.sortOrder < $1.sortOrder }

    var sections: [ListSection] = []
    for entry in sortedGroupEntries {
        let sortedLists = entry.lists.sorted { lhs, rhs in
            let lhsIsBucket = lhs.isBucket
            let rhsIsBucket = rhs.isBucket
            if lhsIsBucket != rhsIsBucket { return lhsIsBucket }
            return (lhs.sortOrder ?? "") < (rhs.sortOrder ?? "")
        }
        sections.append(ListSection(id: "group-\(entry.id)", title: entry.name, lists: sortedLists))
    }

    return sections
}
