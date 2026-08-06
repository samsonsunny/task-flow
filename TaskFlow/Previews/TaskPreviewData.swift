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
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: Schema(versionedSchema: TaskFlowSchemaV9.self),
            configurations: config
        )
    }

    @discardableResult
    static func seedTaskList(into container: ModelContainer) -> [TaskItem] {
        ensureDefaultListExists(in: container.mainContext)
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
        let defaultList = ensureDefaultListExists(in: container.mainContext)
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
        let defaultList = ensureDefaultListExists(in: container.mainContext)
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
        let defaultList = ensureDefaultListExists(in: container.mainContext)
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
        let defaultList = ensureDefaultListExists(in: container.mainContext)
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
        let defaultList = ensureDefaultListExists(in: container.mainContext)
        let tasks = (1...count).map { index in
            TaskItem(taskTitle: "Scroll Task \(index)", dueDate: nil, reminderList: defaultList)
        }
        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    @discardableResult
    static func ensureDefaultListExists(in context: ModelContext) -> ReminderList {
        let descriptor = FetchDescriptor<ReminderList>()
        if let existing = try? context.fetch(descriptor).first(where: { $0.name == ReminderDefaults.defaultListName }) {
            return existing
        }

        let list = ReminderList(name: ReminderDefaults.defaultListName)
        context.insert(list)
        return list
    }
}
