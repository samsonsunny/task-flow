//
//  TaskPreviewData.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

import SwiftData
import Foundation

enum TaskPreviewData {
    static func container() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try! ModelContainer(
            for: Schema(versionedSchema: TaskFlowSchemaV10.self),
            configurations: config
        )
    }

    @discardableResult
    static func seedTaskList(into container: ModelContainer) -> [TaskItem] {
        seedDefaultAreas(in: container.mainContext)
        let task1 = TaskItem(
            taskTitle: "Build iOS App",
            dueDate: Date().addingTimeInterval(86400 * 3)
        )

        let task2 = TaskItem(
            taskTitle: "Learn SwiftUI",
            dueDate: Date().addingTimeInterval(-86400)
        )

        let task3 = TaskItem(
            taskTitle: "Design App Icon",
            dueDate: Date()
        )

        let tasks = [task1, task2, task3]
        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    static func makeDetailTask() -> TaskItem {
        let task = TaskItem(
            taskTitle: "Build iOS App",
            dueDate: Date().addingTimeInterval(86400 * 5)
        )





        return task
    }

    @discardableResult
    static func seedReminderHomeFixture(into container: ModelContainer, now: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        let defaultList = seedDefaultAreas(in: container.mainContext)[0].inboxBucket!
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)

        let todayTask = TaskItem(
            taskTitle: "Confirm travel details",
            dueDate: todayStart,
            reminderList: defaultList
        )

        let tomorrowTask = TaskItem(
            taskTitle: "Reply to design review",
            dueDate: tomorrowStart,
            reminderList: defaultList
        )

        let upcomingTask = TaskItem(
            taskTitle: "Prepare sprint review",
            dueDate: calendar.date(byAdding: .day, value: 3, to: todayStart),
            reminderList: defaultList
        )

        let scheduledTask = TaskItem(
            taskTitle: "Draft launch checklist",
            dueDate: calendar.date(byAdding: .day, value: 8, to: todayStart),
            reminderList: defaultList
        )

        let overdueTask = TaskItem(
            taskTitle: "Pay electricity bill",
            dueDate: calendar.date(byAdding: .day, value: -2, to: todayStart),
            reminderList: defaultList
        )

        let completedTask = TaskItem(
            taskTitle: "Submit tax documents",
            dueDate: calendar.date(byAdding: .day, value: -1, to: todayStart),
            reminderList: defaultList
        )
        completedTask.isCompleted = true
        completedTask.completionDate = now

        let tasks = [
            todayTask,
            tomorrowTask,
            upcomingTask,
            scheduledTask,
            overdueTask,
            completedTask
        ]

        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    @discardableResult
    static func seedUpcomingSectionsFixture(into container: ModelContainer, now: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        let defaultList = seedDefaultAreas(in: container.mainContext)[0].inboxBucket!
        let todayStart = calendar.startOfDay(for: now)
        let insideHorizonDate = calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart
        let laterInsideHorizonDate = calendar.date(byAdding: .day, value: 6, to: todayStart) ?? todayStart
        let farFutureDueDate = calendar.date(byAdding: .day, value: 16, to: todayStart) ?? todayStart

        let tasks = [
            TaskItem(taskTitle: "Prepare roadmap", dueDate: insideHorizonDate, reminderList: defaultList),
            TaskItem(taskTitle: "Plan sprint kickoff", dueDate: laterInsideHorizonDate, reminderList: defaultList),
            TaskItem(taskTitle: "Far future milestone", dueDate: farFutureDueDate, reminderList: defaultList)
        ]

        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    @discardableResult
    static func seedFarFutureUpcomingFixture(into container: ModelContainer, now: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        let defaultList = seedDefaultAreas(in: container.mainContext)[0].inboxBucket!
        let todayStart = calendar.startOfDay(for: now)
        let farFutureDueDate = calendar.date(byAdding: .day, value: 20, to: todayStart) ?? todayStart

        let tasks = [
            TaskItem(taskTitle: "Quarterly planning", dueDate: farFutureDueDate, reminderList: defaultList)
        ]

        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    @discardableResult
    static func seedSubtasksInlineFixture(into container: ModelContainer, now: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        let defaultList = seedDefaultAreas(in: container.mainContext)[0].inboxBucket!
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart

        let parent = TaskItem(
            taskTitle: "Parent Project",
            dueDate: todayStart,
            reminderList: defaultList
        )

        let childToday = TaskItem(
            taskTitle: "Child with today date",
            dueDate: todayStart,
            reminderList: defaultList
        )
        childToday.parentTask = parent

        let childTomorrow = TaskItem(
            taskTitle: "Child with tomorrow date",
            dueDate: tomorrowStart,
            reminderList: defaultList
        )
        childTomorrow.parentTask = parent

        let childNoDate = TaskItem(
            taskTitle: "Child no date",
            dueDate: nil,
            reminderList: defaultList
        )
        childNoDate.parentTask = parent

        parent.subtasks = [childToday, childTomorrow, childNoDate]

        let orphanParent = TaskItem(
            taskTitle: "Orphan parent",
            dueDate: nil,
            reminderList: defaultList
        )

        let orphan = TaskItem(
            taskTitle: "Orphan subtask",
            dueDate: todayStart,
            reminderList: defaultList
        )
        orphan.parentTask = orphanParent
        orphanParent.subtasks = [orphan]

        let tasks = [parent, childToday, childTomorrow, childNoDate, orphanParent, orphan]
        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    @discardableResult
    static func seedManyTasksFixture(into container: ModelContainer, count: Int = 30) -> [TaskItem] {
        let defaultList = seedDefaultAreas(in: container.mainContext)[0].inboxBucket!
        let tasks = (1...count).map { index in
            TaskItem(taskTitle: "Scroll Task \(index)", dueDate: nil, reminderList: defaultList)
        }
        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    /// Seeds the canonical default areas (Work, Personal) each with an Inbox bucket.
    /// Returns the seeded groups ordered Work first, then Personal.
    @discardableResult
    static func seedDefaultAreas(in context: ModelContext) -> [ReminderListGroup] {
        TaskFlow.seedDefaultAreas(in: context)
    }

    // MARK: - Home fixtures

    /// Seeds a both-areas store: Work with an Inbox bucket plus two custom lists,
    /// Personal with an Inbox bucket plus one custom list, and dated tasks in both
    /// areas so Home's sections, summary counts, and the cross-area nudge are all
    /// exercisable in one fixture.
    @discardableResult
    static func seedBothAreasFixture(
        into container: ModelContainer,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [TaskItem] {
        let context = container.mainContext
        let areas = seedDefaultAreas(in: context)
        guard let work = areas.first(where: { $0.name == "Work" }),
              let personal = areas.first(where: { $0.name == "Personal" })
        else { return [] }

        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart

        let workMeetings = makeList(named: "Meetings", in: work, context: context)
        let workProjects = makeList(named: "Projects", in: work, context: context)
        let personalErrands = makeList(named: "Errands", in: personal, context: context)

        var tasks: [TaskItem] = [
            TaskItem(taskTitle: "Standup notes", dueDate: todayStart, reminderList: workMeetings),
            TaskItem(taskTitle: "Overdue invoice", dueDate: yesterdayStart, reminderList: workProjects),
            TaskItem(taskTitle: "Undated backlog item", dueDate: nil, reminderList: work.inboxBucket),
            TaskItem(taskTitle: "Renew passport", dueDate: todayStart, reminderList: personal.inboxBucket),
            TaskItem(taskTitle: "Book dentist", dueDate: tomorrowStart, reminderList: personalErrands)
        ]

        let personalOverdue = TaskItem(taskTitle: "Return library book", dueDate: yesterdayStart, reminderList: personalErrands)
        personalOverdue.notes = "Overdue in the other area — drives the cross-area nudge."
        tasks.append(personalOverdue)

        let personalDone = TaskItem(taskTitle: "Water the plants", dueDate: todayStart, reminderList: personal.inboxBucket)
        personalDone.isCompleted = true
        personalDone.completionDate = now
        tasks.append(personalDone)

        tasks.forEach { context.insert($0) }
        try? context.save()
        return tasks
    }

    /// Seeds a diverged store with a third area, used to verify the silent merge into
    /// Work: "Side Projects" owns a bucket with tasks plus two custom lists.
    @discardableResult
    static func seedThreeAreasFixture(
        into container: ModelContainer,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ReminderListGroup] {
        let context = container.mainContext
        let areas = seedDefaultAreas(in: context)
        guard areas.count == 2 else { return areas }

        let todayStart = calendar.startOfDay(for: now)

        let side = ReminderListGroup(name: "Side Projects")
        context.insert(side)
        side.assignInitialSortOrder(in: context)

        let sideBucket = makeBucket(for: side, in: context)
        let web = makeList(named: "Web", in: side, context: context)
        let copy = makeList(named: "Copy", in: side, context: context)

        let bucketTask = TaskItem(taskTitle: "Side inbox item", dueDate: todayStart, reminderList: sideBucket)
        let webTask = TaskItem(taskTitle: "Landing page", dueDate: nil, reminderList: web)
        let copyTask = TaskItem(taskTitle: "Tagline draft", dueDate: nil, reminderList: copy)
        copyTask.notes = "Must survive the merge untouched."
        [bucketTask, webTask, copyTask].forEach { context.insert($0) }

        try? context.save()
        return areas + [side]
    }

    @discardableResult
    private static func makeList(named name: String, in group: ReminderListGroup, context: ModelContext) -> ReminderList {
        let list = ReminderList(name: name)
        list.group = group
        context.insert(list)
        list.assignInitialSortOrder(in: context)
        return list
    }
}
