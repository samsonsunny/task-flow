import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct ListSectionTests {

    // MARK: - Helpers

    private func makeList(name: String, group: ReminderListGroup? = nil) -> ReminderList {
        let list = ReminderList(name: name)
        list.group = group
        return list
    }

    // MARK: - Section order

    @Test func sectionsInCorrectOrder() {
        let group = ReminderListGroup(name: "Work")
        let work1 = makeList(name: "Project A", group: group)
        let work2 = makeList(name: "Project B", group: group)
        let ungrouped1 = makeList(name: "Shopping")
        let inbox = makeList(name: "Inbox")

        let sections = buildListSections(from: [work1, ungrouped1, work2, inbox])

        #expect(sections.count == 3)
        #expect(sections[0].id == "default")
        #expect(sections[0].lists.map(\.name) == ["Inbox"])
        #expect(sections[1].id == "group-Work")
        #expect(sections[1].title == "Work")
        #expect(sections[1].lists.count == 2)
        #expect(sections[2].id == "ungrouped")
        #expect(sections[2].title == nil)
        #expect(sections[2].lists.map(\.name) == ["Shopping"])
    }

    // MARK: - No groups (5.3)

    @Test func noGroupsProducesDefaultAndUngroupedSections() {
        let list1 = makeList(name: "Shopping")
        let list2 = makeList(name: "Ideas")
        let inbox = makeList(name: "Inbox")

        let sections = buildListSections(from: [list1, list2, inbox])

        #expect(sections.count == 2)
        #expect(sections[0].lists[0].name == "Inbox")
        #expect(sections[1].lists.count == 2)
        #expect(sections.allSatisfy { !$0.id.hasPrefix("group-") })
    }

    @Test func noGroupsAndNoDefaultFlatSingleSection() {
        let list1 = makeList(name: "Shopping")
        let list2 = makeList(name: "Ideas")

        let sections = buildListSections(from: [list1, list2])

        #expect(sections.count == 1)
        #expect(sections[0].id == "ungrouped")
        #expect(sections[0].lists.count == 2)
    }

    // MARK: - Current list excluded (5.2)

    @Test func currentListExcludedFromAllSections() {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let currentList = ReminderList(name: "Current")
        context.insert(currentList)
        let otherList = ReminderList(name: "Other")
        context.insert(otherList)

        let sections = buildListSections(from: [currentList, otherList], excluding: currentList.persistentModelID)

        let allLists = sections.flatMap(\.lists)
        #expect(allLists.count == 1)
        #expect(allLists[0].name == "Other")
    }

    // MARK: - Group assignment (5.4)

    @Test func listsAssignedToCorrectGroupSections() {
        let groupA = ReminderListGroup(name: "Personal")
        let groupB = ReminderListGroup(name: "Work")

        let personal1 = makeList(name: "Home", group: groupA)
        let personal2 = makeList(name: "Fitness", group: groupA)
        let work1 = makeList(name: "Project X", group: groupB)

        let sections = buildListSections(from: [personal1, personal2, work1])

        let personalSection = sections.first { $0.id == "group-Personal" }
        #expect(personalSection != nil)
        #expect(personalSection?.lists.count == 2)

        let workSection = sections.first { $0.id == "group-Work" }
        #expect(workSection != nil)
        #expect(workSection?.lists.count == 1)
        #expect(workSection?.lists[0].name == "Project X")
    }

    // MARK: - Ungrouped at end (5.5)

    @Test func ungroupedListsInFinalSection() {
        let group = ReminderListGroup(name: "Work")
        let work = makeList(name: "Project A", group: group)
        let ungrouped1 = makeList(name: "Shopping")
        let ungrouped2 = makeList(name: "Ideas")

        let sections = buildListSections(from: [work, ungrouped1, ungrouped2])

        let lastSection = sections.last
        #expect(lastSection?.id == "ungrouped")
        #expect(lastSection?.title == nil)
        #expect(lastSection?.lists.map(\.name).sorted() == ["Ideas", "Shopping"])
    }

    // MARK: - Edge cases

    @Test func emptyListsProducesNoSections() {
        let sections = buildListSections(from: [])
        #expect(sections.isEmpty)
    }

    @Test func defaultListNotDuplicatedWhenAlsoInGroup() {
        let group = ReminderListGroup(name: "Work")
        let inbox = makeList(name: "Inbox", group: group)
        let work = makeList(name: "Project A", group: group)

        let sections = buildListSections(from: [inbox, work])

        #expect(sections.count == 2)
        #expect(sections[0].id == "default")
        #expect(sections[0].lists.count == 1)
        #expect(sections[1].id == "group-Work")
        #expect(sections[1].lists.count == 1)
        #expect(sections[1].lists[0].name == "Project A")
    }

    @Test func listSectionIdentity() {
        let section = ListSection(id: "test", title: "Test", lists: [])
        #expect(section.id == "test")
    }
}
