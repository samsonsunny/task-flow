import Testing
import Foundation
import SwiftData
@testable import TaskFlow

@Test func reminderSegmentsCountOnlyMatchingTasks() {
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

    #expect(ReminderSegmentLogic.count(for: .today, tasks: tasks, now: now, calendar: calendar) == 1)
    #expect(ReminderSegmentLogic.count(for: .tomorrow, tasks: tasks, now: now, calendar: calendar) == 1)
    #expect(ReminderSegmentLogic.count(for: .upcoming, tasks: tasks, now: now, calendar: calendar) == 2)
}

@Test func tasksAreSortedByDueDate() {
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
    #expect(titles == ["Older Overdue", "Newer Overdue"])
}

@Test func upcomingFilteringIncludesAllFutureTasksAfterTomorrow() {
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

    #expect(filtered.map(\.safeTitle) == ["Inside Horizon", "Far Future"])
}

@Test func upcomingSectionsIncludeMandatorySevenDayHorizon() {
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

    #expect(sections.count == 2)

    #expect(sections[0].tasks.count == 1)
    #expect(sections[0].tasks.first?.safeTitle == "Horizon Task")
    #expect(sections[0].title == TaskUIModel.tabDateTitle(for: start, calendar: calendar))

    #expect(sections[1].tasks.count == 1)
    #expect(sections[1].tasks.first?.safeTitle == "Beyond Task")
}
