//
//  TaskFlowTests.swift
//  TaskFlowTests
//
//  Created by sam on 26-10-2025.
//

import XCTest
import SwiftData
@testable import TaskFlow

final class TaskFlowTests: XCTestCase {
    func testReminderDraftSaveStateTracksMeaningfulContent() throws {
        var draft = ReminderDraft.empty
        XCTAssertFalse(draft.hasMeaningfulContent)

        draft.title = "Buy milk"
        XCTAssertTrue(draft.hasMeaningfulContent)

        draft.title = ""
        XCTAssertFalse(draft.hasMeaningfulContent)

        draft.priority = .high
        XCTAssertTrue(draft.hasMeaningfulContent)
    }

    @MainActor
    func testReminderDraftMapperUsesDefaultListAndReusesExistingTags() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext

        let existingTag = ReminderTag(label: "Home")
        let existingList = ReminderList(name: ReminderDefaults.defaultListName)
        context.insert(existingTag)
        context.insert(existingList)

        let draft = ReminderDraft(
            title: "Plan trip",
            notes: "Passport renewal",
            urlString: "https://example.com",
            listName: "",
            tagLabels: ["Home", "Urgent"],
            priority: .medium,
            assignedContactName: "Alex",
            imageAttachmentReference: "boarding-pass.png",
            dueDate: makeDate(year: 2026, month: 5, day: 16, calendar: makeCalendar())
        )

        let task = TaskItem()
        ReminderDraftMapper.apply(
            draft,
            to: task,
            availableLists: [existingList],
            availableTags: [existingTag],
            in: context
        )

        XCTAssertEqual(task.safeTitle, "Plan trip")
        XCTAssertEqual(task.notes, "Passport renewal")
        XCTAssertEqual(task.reminderURL, "https://example.com")
        XCTAssertEqual(task.listName, ReminderDefaults.defaultListName)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.assignedContactName, "Alex")
        XCTAssertEqual(task.imageAttachmentReference, "boarding-pass.png")
        XCTAssertEqual(task.tagLabels, ["Home", "Urgent"])
        XCTAssertTrue(task.tags.contains(where: { $0 === existingTag }))
    }

    func testReminderSegmentsCountOnlyMatchingTasks() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 5, day: 13, calendar: calendar)
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)

        let todayTask = TaskItem(taskTitle: "Today", dueDate: todayStart)
        let tomorrowTask = TaskItem(taskTitle: "Tomorrow", dueDate: tomorrowStart)
        let upcomingTask = TaskItem(taskTitle: "Upcoming", dueDate: calendar.date(byAdding: .day, value: 3, to: todayStart))
        let scheduledTask = TaskItem(taskTitle: "Scheduled", dueDate: calendar.date(byAdding: .day, value: 12, to: todayStart))
        let overdueTask = TaskItem(taskTitle: "Overdue", dueDate: calendar.date(byAdding: .day, value: -1, to: todayStart))
        let completedTask = TaskItem(taskTitle: "Completed", dueDate: todayStart)
        completedTask.isCompleted = true
        completedTask.completionDate = now

        let tasks = [todayTask, tomorrowTask, upcomingTask, scheduledTask, overdueTask, completedTask]

        XCTAssertEqual(ReminderSegmentLogic.count(for: .today, tasks: tasks, now: now, calendar: calendar), 1)
        XCTAssertEqual(ReminderSegmentLogic.count(for: .tomorrow, tasks: tasks, now: now, calendar: calendar), 1)
        XCTAssertEqual(ReminderSegmentLogic.count(for: .upcoming, tasks: tasks, now: now, calendar: calendar), 2) // Now includes scheduledTask (D+12)
    }

    func testTasksAreSortedByDueDate() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 5, day: 13, calendar: calendar)
        let todayStart = calendar.startOfDay(for: now)

        let olderOverdue = TaskItem(
            taskTitle: "Older Overdue",
            dueDate: calendar.date(byAdding: .day, value: -5, to: todayStart)
        )
        let newerOverdue = TaskItem(
            taskTitle: "Newer Overdue",
            dueDate: calendar.date(byAdding: .day, value: -1, to: todayStart)
        )

        let sorted: [TaskItem] = ReminderSegmentLogic.sortedTasks([newerOverdue, olderOverdue], for: .today, calendar: calendar)

        let titles: [String] = sorted.map(\.safeTitle)
        XCTAssertEqual(titles, ["Older Overdue", "Newer Overdue"])
    }

    func testUpcomingFilteringIncludesAllFutureTasksAfterTomorrow() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 5, day: 13, calendar: calendar)
        let todayStart = calendar.startOfDay(for: now)
        let start = ReminderSegmentLogic.upcomingStart(now: now, calendar: calendar)

        let tomorrowTask = TaskItem(taskTitle: "Tomorrow", dueDate: calendar.date(byAdding: .day, value: 1, to: todayStart))
        let firstUpcomingTask = TaskItem(taskTitle: "Inside Horizon", dueDate: start)
        let farFutureTask = TaskItem(taskTitle: "Far Future", dueDate: calendar.date(byAdding: .day, value: 100, to: start))
        let completedTask = TaskItem(taskTitle: "Completed", dueDate: calendar.date(byAdding: .day, value: 2, to: todayStart))
        completedTask.isCompleted = true

        let filtered = ReminderSegmentLogic.filteredTasks(
            [tomorrowTask, firstUpcomingTask, farFutureTask, completedTask],
            for: .upcoming,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(filtered.map(\.safeTitle), ["Inside Horizon", "Far Future"])
    }

    func testUpcomingSectionsIncludeMandatorySevenDayHorizon() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 5, day: 13, calendar: calendar)
        let start = ReminderSegmentLogic.upcomingStart(now: now, calendar: calendar)

        let taskInHorizon = TaskItem(taskTitle: "Horizon Task", dueDate: start)
        let taskBeyondHorizon = TaskItem(taskTitle: "Beyond Task", dueDate: calendar.date(byAdding: .day, value: 10, to: start))

        let sections = ReminderSegmentLogic.datedSections(
            from: [taskInHorizon, taskBeyondHorizon],
            for: .upcoming,
            now: now,
            calendar: calendar
        )

        // Sections only created for days with tasks (empty days filtered out)
        XCTAssertEqual(sections.count, 2)

        // First section: day section with horizon task
        XCTAssertEqual(sections[0].tasks.count, 1)
        XCTAssertEqual(sections[0].tasks.first?.safeTitle, "Horizon Task")
        XCTAssertEqual(sections[0].title, TaskUIModel.tabDateTitle(for: start, calendar: calendar))

        // Second section: remainder-of-month section with beyond-horizon task
        XCTAssertEqual(sections[1].tasks.count, 1)
        XCTAssertEqual(sections[1].tasks.first?.safeTitle, "Beyond Task")
    }


    func testMidpointBothNil() throws {
        let result = midpoint(between: nil, and: nil)
        XCTAssertEqual(result, "m")
    }

    func testMidpointNoLower() throws {
        let result = midpoint(between: nil, and: "m")
        XCTAssertNotNil(result)
        XCTAssertTrue(result! < "m", "\(result!) should be < m")
    }

    func testMidpointNoUpper() throws {
        let result = midpoint(between: "a", and: nil)
        XCTAssertNotNil(result)
        XCTAssertTrue(result! > "a", "\(result!) should be > a")
    }

    func testMidpointAdjacentLetters() throws {
        let result = midpoint(between: "a", and: "b")
        XCTAssertNotNil(result)
        XCTAssertTrue(result! > "a" && result! < "b", "\(result!) should be between a and b")
    }

    func testMidpointWithinWord() throws {
        let result = midpoint(between: "a", and: "am")
        XCTAssertNotNil(result)
        XCTAssertTrue(result! > "a" && result! < "am", "\(result!) should be between a and am")
    }

    func testMidpointLongerStrings() throws {
        let result = midpoint(between: "an", and: "b")
        XCTAssertNotNil(result)
        XCTAssertTrue(result! > "an" && result! < "b", "\(result!) should be between an and b")
    }

    func testMidpointPrefixEdge() throws {
        let result = midpoint(between: "m", and: "mc")
        XCTAssertNotNil(result)
        XCTAssertTrue(result! > "m" && result! < "mc", "\(result!) should be between m and mc")
    }

    func testMidpointChainProducesAscendingOrder() throws {
        let a = midpoint(between: nil, and: nil)!
        let b = midpoint(between: a, and: nil)!
        let c = midpoint(between: b, and: nil)!
        let d = midpoint(between: c, and: nil)!
        let sorted = [d, c, b, a].sorted()
        XCTAssertEqual(sorted, [a, b, c, d])
    }

    func testMidpointReturnsNilForImpossibleGap() throws {
        let result = midpoint(between: "f", and: "fa")
        XCTAssertNil(result, "should return nil when no valid string exists between bounds")
    }

    func testMidpointAfterWidenWorks() throws {
        let widened = widen("fa")
        XCTAssertEqual(widened, "faz")
        let result = midpoint(between: "f", and: widened)
        XCTAssertNotNil(result)
        XCTAssertTrue(result! > "f" && result! < widened, "\(result!) should be between f and faz")
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    // MARK: - Test Infrastructure

    @MainActor
    private func createDetailViewModel(
        list: ReminderList,
        allTasks: [TaskItem],
        context: ModelContext
    ) -> ListDetailViewModel {
        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        vm.update(tasks: allTasks, lists: [list], allTasks: allTasks)
        return vm
    }

    @MainActor
    private func createListsTabViewModel(
        lists: [ReminderList],
        groups: [ReminderListGroup],
        allTasks: [TaskItem],
        context: ModelContext
    ) -> ListsTabViewModel {
        let vm = ListsTabViewModel(modelContext: context)
        vm.update(lists: lists, groups: groups, allTasks: allTasks)
        return vm
    }

    private func assertValidTaskSortOrders(_ tasks: [TaskItem], file: StaticString = #filePath, line: UInt = #line) {
        let orders = tasks.map { $0.sortOrder }
        let nonNil = orders.compactMap { $0 }
        XCTAssertEqual(nonNil.count, orders.count, "All sortOrders should be non-nil", file: file, line: line)
        XCTAssertEqual(Set(nonNil).count, nonNil.count, "sortOrders should be unique", file: file, line: line)
        XCTAssertEqual(nonNil.sorted(), nonNil, "sortOrders should be in increasing order", file: file, line: line)
    }

    private func assertValidListSortOrders(_ lists: [ReminderList], file: StaticString = #filePath, line: UInt = #line) {
        let orders = lists.map { $0.sortOrder }
        let nonNil = orders.compactMap { $0 }
        XCTAssertEqual(nonNil.count, orders.count, "All sortOrders should be non-nil", file: file, line: line)
        XCTAssertEqual(Set(nonNil).count, nonNil.count, "sortOrders should be unique", file: file, line: line)
        XCTAssertEqual(nonNil.sorted(), nonNil, "sortOrders should be in increasing order", file: file, line: line)
    }

    @MainActor
    private func makeTasks(sortOrders: [String?]) -> [TaskItem] {
        sortOrders.enumerated().map { (i, order) in
            let task = TaskItem(taskTitle: "Task \(i)", dueDate: nil)
            task.sortOrder = order
            return task
        }
    }

    private func sortedBySortOrder(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
    }

    // MARK: - Midpoint Edge Cases

    func testMidpointNilAndEmptyString() throws {
        let result = midpoint(between: nil, and: "")
        XCTAssertNotNil(result)
        XCTAssertTrue(result! < "", "\(result!) should be < empty string")
    }

    func testMidpointExhaustionChainWidensPreservingOrder() throws {
        var lower: String? = nil
        var upper: String? = "b"
        var results: [String] = []
        for _ in 0..<20 {
            if let m = midpoint(between: lower, and: upper) {
                results.append(m)
                upper = m
            } else {
                let w = widen(upper!)
                results.append(w)
                upper = w
                if let m = midpoint(between: lower, and: upper) {
                    results.append(m)
                    upper = m
                }
            }
        }
        XCTAssertEqual(results.sorted(), results, "Chain should produce ascending order")
    }

    func testMidpointReturnsNilForImpossibleGapRecovery() throws {
        let result = midpoint(between: "f", and: "fa")
        XCTAssertNil(result)
        let widened = widen("fa")
        let recovered = midpoint(between: "f", and: widened)
        XCTAssertNotNil(recovered)
        XCTAssertTrue(recovered! > "f" && recovered! < widened)
    }

    // MARK: - assignSortOrder Tests

    @MainActor
    func testAssignSortOrderPlacesAtEndOfExistingList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let existing = makeTasks(sortOrders: ["m", "t", "w"])
        existing.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: existing, context: context)
        let newTask = TaskItem(taskTitle: "New", dueDate: nil)
        context.insert(newTask)
        vm.assignSortOrder(for: newTask, in: list)

        XCTAssertNotNil(newTask.sortOrder)
        let all = existing + [newTask]
        let sorted = sortedBySortOrder(all)
        XCTAssertEqual(sorted.last?.taskTitle, "New")
        assertValidTaskSortOrders(all)
    }

    @MainActor
    func testAssignSortOrderForSingleItemList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let existing = makeTasks(sortOrders: ["m"])
        existing.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: existing, context: context)
        let newTask = TaskItem(taskTitle: "New", dueDate: nil)
        context.insert(newTask)
        vm.assignSortOrder(for: newTask, in: list)

        XCTAssertNotNil(newTask.sortOrder)
        XCTAssertTrue(newTask.sortOrder! > "m")
    }

    @MainActor
    func testAssignSortOrderForFirstTaskInEmptyList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: [], context: context)
        let task = TaskItem(taskTitle: "First", dueDate: nil)
        vm.assignSortOrder(for: task, in: list)

        XCTAssertNotNil(task.sortOrder)
        XCTAssertEqual(task.sortOrder, "m")
    }

    // MARK: - moveTasks Tests

    @MainActor
    func testMoveFirstTaskToLastPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 0), toOffset: 4)

        let sorted = sortedBySortOrder(tasks)
        XCTAssertEqual(sorted.map { $0.taskTitle }, ["Task 1", "Task 2", "Task 3", "Task 0"])
        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    func testMoveLastTaskToFirstPosition() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 3), toOffset: 0)

        let sorted = sortedBySortOrder(tasks)
        XCTAssertEqual(sorted.map { $0.taskTitle }, ["Task 3", "Task 0", "Task 1", "Task 2"])
        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    func testMoveTaskToSameIndexIsNoOp() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let beforeOrders = tasks.map { $0.sortOrder }
        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 1)

        let afterOrders = tasks.map { $0.sortOrder }
        XCTAssertEqual(beforeOrders, afterOrders)
        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    func testMoveMultipleNonAdjacentItems() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet([0, 2]), toOffset: 4)

        let sorted = sortedBySortOrder(tasks)
        XCTAssertEqual(sorted.map { $0.taskTitle }, ["Task 1", "Task 3", "Task 0", "Task 2"])
        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    func testMoveAdjacentItemsDoesNotCrash() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "e", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet([2, 3]), toOffset: 0)

        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    func testMoveTasksMidpointExhaustionTriggersWiden() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["f", "fa"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let newTask = TaskItem(taskTitle: "Inserted", dueDate: nil)
        newTask.reminderList = list
        context.insert(newTask)
        try? context.save()

        let allTasks = tasks + [newTask]
        let vm = createDetailViewModel(list: list, allTasks: allTasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 2), toOffset: 2)

        assertValidTaskSortOrders(allTasks)
        let sorted = sortedBySortOrder(allTasks)
        XCTAssertEqual(sorted.map { $0.taskTitle }, ["Task 0", "Inserted", "Task 1"])
    }

    // MARK: - handleDrop Tests

    @MainActor
    func testDropOnUpperZoneReordersAmongSiblings() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[2].taskId
        vm.handleDrop(target: tasks[1], location: CGPoint(x: 0, y: 10))

        assertValidTaskSortOrders(tasks)
        let sorted = sortedBySortOrder(tasks)
        XCTAssertEqual(sorted.map { $0.taskTitle }, ["Task 0", "Task 2", "Task 1"])
        XCTAssertNil(sorted[1].parentTask)
        XCTAssertNil(sorted[2].parentTask)
    }

    @MainActor
    func testDropOnLowerZoneMakesChild() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[2].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        XCTAssertEqual(tasks[2].parentTask?.persistentModelID, tasks[0].persistentModelID)
        assertValidTaskSortOrders(tasks)
    }

    @MainActor
    func testDropTaskOnItselfIsNoOp() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[0].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        XCTAssertNil(tasks[0].parentTask)
        XCTAssertEqual(tasks[0].sortOrder, "a")
    }

    @MainActor
    func testDropParentOnDescendantIsRejected() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        tasks[1].parentTask = tasks[0]
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[0].taskId
        vm.handleDrop(target: tasks[1], location: CGPoint(x: 0, y: 30))

        XCTAssertEqual(tasks[1].parentTask?.persistentModelID, tasks[0].persistentModelID)
    }

    @MainActor
    func testDropIntoTaskWithExistingSubtasks() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m", "t", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        tasks[1].parentTask = tasks[0]
        tasks[2].parentTask = tasks[0]
        let subtaskSortOrders = [tasks[1].sortOrder, tasks[2].sortOrder]
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[3].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        XCTAssertEqual(tasks[3].parentTask?.persistentModelID, tasks[0].persistentModelID)
        let children = tasks[0].subtasks.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        XCTAssertEqual(children.count, 3)
        assertValidTaskSortOrders(Array(tasks[0].subtasks))
    }

    @MainActor
    func testDropIntoTaskWithNoSubtasks() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
        vm.draggedTaskId = tasks[1].taskId
        vm.handleDrop(target: tasks[0], location: CGPoint(x: 0, y: 30))

        XCTAssertEqual(tasks[1].parentTask?.persistentModelID, tasks[0].persistentModelID)
        XCTAssertEqual(tasks[0].subtasks.count, 1)
    }

    // MARK: - moveTaskToRoot Tests

    @MainActor
    func testMoveNestedTaskToEmptyRoot() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["m"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        let nested = TaskItem(taskTitle: "Nested", dueDate: nil)
        nested.sortOrder = "a"
        nested.parentTask = tasks[0]
        nested.reminderList = list
        context.insert(nested)
        try? context.save()

        let allTasks = tasks + [nested]
        let vm = createDetailViewModel(list: list, allTasks: allTasks, context: context)
        vm.draggedTaskId = nested.taskId
        vm.moveTaskToRoot()

        XCTAssertNil(nested.parentTask)
        XCTAssertNotNil(nested.sortOrder)
        assertValidTaskSortOrders(allTasks)
    }

    @MainActor
    func testMoveNestedTaskToRootWithExistingSiblings() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let tasks = makeTasks(sortOrders: ["a", "t"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        let nested = TaskItem(taskTitle: "Nested", dueDate: nil)
        nested.sortOrder = "m"
        nested.parentTask = tasks[0]
        nested.reminderList = list
        context.insert(nested)
        try? context.save()

        let allTasks = tasks + [nested]
        let vm = createDetailViewModel(list: list, allTasks: allTasks, context: context)
        vm.draggedTaskId = nested.taskId
        vm.moveTaskToRoot()

        XCTAssertNil(nested.parentTask)
        let rootTasks = allTasks.filter { $0.parentTask == nil }
        assertValidTaskSortOrders(rootTasks)
        let sorted = sortedBySortOrder(rootTasks)
        XCTAssertEqual(sorted.map { $0.taskTitle }, ["Task 0", "Nested", "Task 1"])
    }

    // MARK: - moveLists Tests

    @MainActor
    func testMoveListWithinSameGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Group A")
        context.insert(group)
        let lists = [
            ReminderList(name: "Alpha"),
            ReminderList(name: "Beta"),
            ReminderList(name: "Gamma")
        ]
        lists.forEach { $0.group = group; $0.sortOrder = ["a", "m", "t"][lists.firstIndex(of: $0)!]; context.insert($0) }
        try? context.save()

        let vm = createListsTabViewModel(lists: lists, groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 2), toOffset: 0, in: lists, group: group)

        for list in lists {
            XCTAssertEqual(list.group?.persistentModelID, group.persistentModelID)
        }
        assertValidListSortOrders(lists)
    }

    @MainActor
    func testMoveListToDifferentGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let groupA = ReminderListGroup(name: "Group A")
        let groupB = ReminderListGroup(name: "Group B")
        context.insert(groupA)
        context.insert(groupB)
        let list = ReminderList(name: "Moveable")
        list.sortOrder = "m"
        list.group = groupA
        context.insert(list)
        let existingInB = ReminderList(name: "Existing B")
        existingInB.sortOrder = "a"
        existingInB.group = groupB
        context.insert(existingInB)
        try? context.save()

        let vm = createListsTabViewModel(lists: [list, existingInB], groups: [groupA, groupB], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 1, in: [list], group: groupB)

        XCTAssertEqual(list.group?.persistentModelID, groupB.persistentModelID)
    }

    @MainActor
    func testMoveListToEmptyGroup() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let group = ReminderListGroup(name: "Empty Group")
        context.insert(group)
        let list = ReminderList(name: "Solo")
        list.sortOrder = "m"
        context.insert(list)
        try? context.save()

        let vm = createListsTabViewModel(lists: [list], groups: [group], allTasks: [], context: context)
        vm.moveLists(fromOffsets: IndexSet(integer: 0), toOffset: 0, in: [list], group: group)

        XCTAssertEqual(list.group?.persistentModelID, group.persistentModelID)
        XCTAssertNotNil(list.sortOrder)
    }

    // MARK: - isDescendant Tests

    @MainActor
    func testIsDescendantDirectParent() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let parent = TaskItem(taskTitle: "Parent", dueDate: nil)
        let child = TaskItem(taskTitle: "Child", dueDate: nil)
        child.parentTask = parent

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        XCTAssertTrue(vm.isDescendant(child, of: parent))
    }

    @MainActor
    func testIsDescendantGrandparent() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let grandparent = TaskItem(taskTitle: "GP", dueDate: nil)
        let parent = TaskItem(taskTitle: "Parent", dueDate: nil)
        let child = TaskItem(taskTitle: "Child", dueDate: nil)
        parent.parentTask = grandparent
        child.parentTask = parent

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        XCTAssertTrue(vm.isDescendant(child, of: grandparent))
    }

    @MainActor
    func testIsDescendantUnrelatedReturnsFalse() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let taskA = TaskItem(taskTitle: "A", dueDate: nil)
        let taskB = TaskItem(taskTitle: "B", dueDate: nil)

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        XCTAssertFalse(vm.isDescendant(taskA, of: taskB))
    }

    @MainActor
    func testIsDescendantSelfReturnsFalse() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let task = TaskItem(taskTitle: "Self", dueDate: nil)

        let vm = ListDetailViewModel(modelContext: context, listID: list.persistentModelID)
        XCTAssertFalse(vm.isDescendant(task, of: task))
    }

    // MARK: - commitQuickCapture Tests

    @MainActor
    func testQuickCaptureAssignsSortOrderInNonEmptyList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        let existing = makeTasks(sortOrders: ["a", "m"])
        existing.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: existing, context: context)
        vm.update(tasks: existing, lists: [list], allTasks: existing)
        vm.commitQuickCapture(text: "Quick", in: list.persistentModelID)

        let allTasks = existing + (try! context.fetch(FetchDescriptor<TaskItem>()).filter { $0.taskTitle == "Quick" })
        let newTask = allTasks.first { $0.taskTitle == "Quick" }
        XCTAssertNotNil(newTask)
        XCTAssertNotNil(newTask?.sortOrder)
        assertValidTaskSortOrders(allTasks)
        let sorted = sortedBySortOrder(allTasks)
        XCTAssertEqual(sorted.last?.taskTitle, "Quick")
    }

    @MainActor
    func testQuickCaptureAssignsSortOrderInEmptyList() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        try? context.save()

        let vm = createDetailViewModel(list: list, allTasks: [], context: context)
        vm.update(tasks: [], lists: [list], allTasks: [])
        vm.commitQuickCapture(text: "First", in: list.persistentModelID)

        let quickTasks = try! context.fetch(FetchDescriptor<TaskItem>()).filter { $0.taskTitle == "First" }
        XCTAssertEqual(quickTasks.count, 1)
        XCTAssertNotNil(quickTasks[0].sortOrder)
    }

    // MARK: - Property-Based Invariant Tests

    @MainActor
    func testChainOfReordersAtSamePositionPreservesInvariants() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let list = ReminderList(name: "Test")
        context.insert(list)
        var tasks = makeTasks(sortOrders: ["a", "z"])
        tasks.forEach { $0.reminderList = list; context.insert($0) }
        try? context.save()

        for i in 0..<10 {
            let newTask = TaskItem(taskTitle: "Insert \(i)", dueDate: nil)
            newTask.sortOrder = nil
            newTask.reminderList = list
            context.insert(newTask)
            tasks.append(newTask)
            try? context.save()

            let vm = createDetailViewModel(list: list, allTasks: tasks, context: context)
            vm.moveTasks(fromOffsets: IndexSet(integer: tasks.count - 1), toOffset: 1)
            assertValidTaskSortOrders(tasks)
        }
    }

    @MainActor
    func testCrossListMoveAndReorderPreservesInvariants() throws {
        let container = TaskPreviewData.container()
        let context = container.mainContext
        let listA = ReminderList(name: "A")
        let listB = ReminderList(name: "B")
        context.insert(listA)
        context.insert(listB)
        let tasksA = makeTasks(sortOrders: ["a", "m"])
        tasksA.forEach { $0.reminderList = listA; context.insert($0) }
        let tasksB = makeTasks(sortOrders: ["t"])
        tasksB.forEach { $0.reminderList = listB; context.insert($0) }
        try? context.save()

        let allTasks = tasksA + tasksB
        let vm = createDetailViewModel(list: listA, allTasks: allTasks, context: context)
        vm.moveTasks(fromOffsets: IndexSet(integer: 1), toOffset: 0)

        assertValidTaskSortOrders(tasksA)
    }
}
