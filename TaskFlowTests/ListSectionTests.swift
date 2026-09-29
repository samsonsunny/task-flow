import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@MainActor
struct ListSectionTests {

    // MARK: - Helpers

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() {
        container = TaskPreviewData.container()
    }

    private func makeGroup(_ name: String) -> ReminderListGroup {
        let group = ReminderListGroup(name: name)
        context.insert(group)
        return group
    }

    private func makeList(_ name: String, group: ReminderListGroup? = nil, sortOrder: String? = nil) -> ReminderList {
        let list = ReminderList(name: name, sortOrder: sortOrder)
        list.group = group
        context.insert(list)
        return list
    }

    /// A bucket is just the area's list named "Inbox" — identity is derived, not stored.
    private func makeBucket(for group: ReminderListGroup) -> ReminderList {
        makeList("Inbox", group: group)
    }

    // MARK: - Section order

    @Test func sectionsInCorrectOrder() {
        let group = makeGroup("Work")
        let inbox = makeBucket(for: group)
        let work1 = makeList("Project A", group: group)
        let work2 = makeList("Project B", group: group)
        try? context.save()

        let sections = buildListSections(from: [work1, work2, inbox])

        #expect(sections.count == 1)
        #expect(sections[0].id == "group-\(group.persistentModelID)")
        #expect(sections[0].title == "Work")
        #expect(sections[0].lists.map(\.name) == ["Inbox", "Project A", "Project B"])
    }

    @Test func bucketPinnedFirstWithinGroup() {
        let group = makeGroup("Personal")
        let bucket = makeBucket(for: group)
        let listA = makeList("Zebra", group: group, sortOrder: "m")
        let listB = makeList("Alpha", group: group, sortOrder: "a")
        try? context.save()

        let sections = buildListSections(from: [listA, bucket, listB])

        let personalLists = sections[0].lists
        #expect(personalLists.first?.persistentModelID == bucket.persistentModelID)
        #expect(personalLists.map(\.name) == ["Inbox", "Alpha", "Zebra"])
    }

    // MARK: - No groups

    @Test func noGroupsProducesNoSections() {
        let list1 = makeList("Shopping")
        let list2 = makeList("Ideas")
        try? context.save()

        let sections = buildListSections(from: [list1, list2])

        #expect(sections.isEmpty)
    }

    // MARK: - Current list excluded

    @Test func currentListExcludedFromAllSections() {
        let group = makeGroup("Work")
        let bucket = makeBucket(for: group)
        let currentList = makeList("Current", group: group, sortOrder: "m")
        let otherList = makeList("Other", group: group, sortOrder: "a")
        try? context.save()

        let sections = buildListSections(from: [currentList, otherList, bucket], excluding: currentList.persistentModelID)

        let allLists = sections.flatMap(\.lists)
        #expect(allLists.count == 2)
        #expect(allLists.contains { $0.name == "Current" } == false)
        #expect(allLists.contains { $0.name == "Other" })
    }

    // MARK: - Group assignment

    @Test func listsAssignedToCorrectGroupSections() {
        let groupA = makeGroup("Personal")
        let groupB = makeGroup("Work")

        let personalInbox = makeBucket(for: groupA)
        let personal1 = makeList("Home", group: groupA)
        let personal2 = makeList("Fitness", group: groupA)
        let work1 = makeList("Project X", group: groupB)
        try? context.save()

        let sections = buildListSections(from: [personal1, personal2, work1, personalInbox])

        let personalSection = sections.first { $0.title == "Personal" }
        #expect(personalSection != nil)
        #expect(personalSection?.lists.count == 3)

        let workSection = sections.first { $0.title == "Work" }
        #expect(workSection != nil)
        #expect(workSection?.lists.count == 1)
        #expect(workSection?.lists[0].name == "Project X")
    }

    // MARK: - Edge cases

    @Test func emptyListsProducesNoSections() {
        let sections = buildListSections(from: [])
        #expect(sections.isEmpty)
    }

    @Test func bucketNotDuplicatedWhenAlsoInGroup() {
        let group = makeGroup("Work")
        let inbox = makeBucket(for: group)
        let work = makeList("Project A", group: group)
        try? context.save()

        let sections = buildListSections(from: [inbox, work])

        #expect(sections.count == 1)
        let names = sections[0].lists.map(\.name)
        #expect(names == ["Inbox", "Project A"])
    }

    @Test func groupSectionsSortByGroupSortOrder() {
        let second = makeGroup("Personal")
        second.sortOrder = "m"
        makeBucket(for: second)
        let first = makeGroup("Work")
        first.sortOrder = "a"
        makeBucket(for: first)
        try? context.save()
        let lists = (try? context.fetch(FetchDescriptor<ReminderList>())) ?? []

        let sections = buildListSections(from: lists)

        #expect(sections.map(\.title) == ["Work", "Personal"])
    }

    @Test func listSectionIdentity() {
        let section = ListSection(id: "test", title: "Test", lists: [])
        #expect(section.id == "test")
    }
}
