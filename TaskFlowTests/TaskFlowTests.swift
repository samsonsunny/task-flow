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

        // 7 mandatory days + 1 for beyond task
        XCTAssertEqual(sections.count, 8)
        
        // Verify first day has task
        XCTAssertEqual(sections[0].tasks.count, 1)
        XCTAssertEqual(sections[0].title, "Fri, May 15")
        
        // Verify middle day is empty but present
        XCTAssertEqual(sections[1].tasks.count, 0)
        XCTAssertEqual(sections[1].title, "Sat, May 16")
        
        // Verify beyond section is present
        XCTAssertEqual(sections.last?.tasks.count, 1)
        XCTAssertEqual(sections.last?.tasks.first?.safeTitle, "Beyond Task")
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
}
