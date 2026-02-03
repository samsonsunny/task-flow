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
            for: TaskItem.self, Subtask.self, DailyLogEntry.self,
            configurations: config
        )
    }

    @discardableResult
    static func seedTaskList(into container: ModelContainer) -> [TaskItem] {
        let task1 = TaskItem(
            taskTitle: "Build iOS App",
            taskDescription: "Create a task management app with SwiftData",
            dueDate: Date().addingTimeInterval(86400 * 3)
        )

        let task2 = TaskItem(
            taskTitle: "Learn SwiftUI",
            taskDescription: "Master SwiftUI fundamentals",
            isCompleted: true,
            dueDate: Date().addingTimeInterval(-86400)
        )
        task2.completionDate = Date()

        let task3 = TaskItem(
            taskTitle: "Design App Icon",
            taskDescription: "Create a modern app icon",
            dueDate: Date()
        )

        let subtask1 = Subtask(title: "Set up project")
        let subtask2 = Subtask(title: "Create models", completed: true)
        task1.subtasks = [subtask1, subtask2]

        let tasks = [task1, task2, task3]
        tasks.forEach { container.mainContext.insert($0) }
        return tasks
    }

    static func makeDetailTask() -> TaskItem {
        let task = TaskItem(
            taskTitle: "Build iOS App",
            taskDescription: "Create a comprehensive task management app with SwiftData and iCloud sync capabilities.",
            dueDate: Date().addingTimeInterval(86400 * 5)
        )

        let subtask1 = Subtask(title: "Design data models")
        let subtask2 = Subtask(title: "Implement UI", completed: true)
        let subtask3 = Subtask(title: "Add iCloud sync")
        task.subtasks = [subtask1, subtask2, subtask3]

        let log1 = DailyLogEntry(
            timestamp: Date().addingTimeInterval(-7200),
            note: "Started working on the task detail view. Made good progress with the layout."
        )
        let log2 = DailyLogEntry(
            timestamp: Date().addingTimeInterval(-3600),
            note: "Added subtask functionality. Need to test edge cases tomorrow."
        )
        task.dailyLog = [log1, log2]

        return task
    }
}
