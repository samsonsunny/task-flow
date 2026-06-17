//
//  TaskItem.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

import Foundation
import SwiftData

enum TaskFlowSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TaskItem.self]
    }

    @Model
    final class TaskItem {
        var taskId: String?
        var taskTitle: String?
        var taskDescription: String?
        var isCompleted: Bool?
        var isFlagged: Bool?
        var completionDate: Date?
        var dueDate: Date?
        var createdAt: Date?

        init(
            taskId: String? = UUID().uuidString,
            taskTitle: String? = "",
            taskDescription: String? = "",
            dueDate: Date? = nil,
            createdAt: Date? = Date()
        ) {
            self.taskId = taskId
            self.taskTitle = taskTitle
            self.taskDescription = taskDescription
            self.isCompleted = false
            self.isFlagged = false
            self.dueDate = dueDate
            self.createdAt = createdAt
        }
    }
}

enum TaskFlowSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TaskItem.self, ReminderList.self, ReminderTag.self]
    }

    @Model
    final class TaskItem {
        var taskId: String?
        var taskTitle: String?
        // Keep for backward compatibility with existing stores. Notes use this field as storage.
        var taskDescription: String?
        // Keep for backward compatibility with existing stores. Do not remove without a migration plan.
        var isCompleted: Bool?
        // Keep optional for backward compatibility with existing stores.
        var isFlagged: Bool?
        // Keep for backward compatibility with existing stores. Do not remove without a migration plan.
        var completionDate: Date?
        var dueDate: Date?
        var createdAt: Date?

        var urlString: String?
        var priorityRawValue: String?
        var assignedContactName: String?
        var imageAttachmentReference: String?
        @Relationship(inverse: \ReminderList.reminders) var reminderList: ReminderList?
        @Relationship var tags: [ReminderTag]

        init(
            taskId: String? = UUID().uuidString,
            taskTitle: String? = "",
            taskDescription: String? = "",
            dueDate: Date? = nil,
            createdAt: Date? = Date(),
            urlString: String? = nil,
            priorityRawValue: String? = ReminderPriority.none.rawValue,
            assignedContactName: String? = nil,
            imageAttachmentReference: String? = nil,
            reminderList: ReminderList? = nil,
            tags: [ReminderTag] = []
        ) {
            self.taskId = taskId
            self.taskTitle = taskTitle
            self.taskDescription = taskDescription
            self.isCompleted = false
            self.isFlagged = false
            self.dueDate = dueDate
            self.createdAt = createdAt
            self.urlString = urlString
            self.priorityRawValue = priorityRawValue
            self.assignedContactName = assignedContactName
            self.imageAttachmentReference = imageAttachmentReference
            self.reminderList = reminderList
            self.tags = tags
        }
    }

    @Model
    final class ReminderList {
        var name: String
        var createdAt: Date
        var reminders: [TaskItem]

        init(name: String, createdAt: Date = Date(), reminders: [TaskItem] = []) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
        }
    }

    @Model
    final class ReminderTag {
        var label: String
        var normalizedLabel: String

        init(label: String) {
            self.label = label
            self.normalizedLabel = ReminderTag.normalize(label)
        }

        static func normalize(_ label: String) -> String {
            label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}

enum TaskFlowSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TaskItem.self, ReminderList.self, ReminderTag.self]
    }

    @Model
    final class TaskItem {
        var taskId: String?
        var taskTitle: String?
        var taskDescription: String?
        var isCompleted: Bool?
        var isFlagged: Bool?
        var completionDate: Date?
        var dueDate: Date?
        var createdAt: Date?

        var urlString: String?
        var priorityRawValue: String?
        var assignedContactName: String?
        var imageAttachmentReference: String?
        @Relationship(inverse: \ReminderList.reminders) var reminderList: ReminderList?
        @Relationship var tags: [ReminderTag]

        var sortOrder: String?

        init(
            taskId: String? = UUID().uuidString,
            taskTitle: String? = "",
            taskDescription: String? = "",
            dueDate: Date? = nil,
            createdAt: Date? = Date(),
            urlString: String? = nil,
            priorityRawValue: String? = ReminderPriority.none.rawValue,
            assignedContactName: String? = nil,
            imageAttachmentReference: String? = nil,
            reminderList: ReminderList? = nil,
            tags: [ReminderTag] = [],
            sortOrder: String? = nil
        ) {
            self.taskId = taskId
            self.taskTitle = taskTitle
            self.taskDescription = taskDescription
            self.isCompleted = false
            self.isFlagged = false
            self.dueDate = dueDate
            self.createdAt = createdAt
            self.urlString = urlString
            self.priorityRawValue = priorityRawValue
            self.assignedContactName = assignedContactName
            self.imageAttachmentReference = imageAttachmentReference
            self.reminderList = reminderList
            self.tags = tags
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class ReminderList {
        var name: String
        var createdAt: Date
        var reminders: [TaskItem]

        init(name: String, createdAt: Date = Date(), reminders: [TaskItem] = []) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
        }
    }

    @Model
    final class ReminderTag {
        var label: String
        var normalizedLabel: String

        init(label: String) {
            self.label = label
            self.normalizedLabel = ReminderTag.normalize(label)
        }

        static func normalize(_ label: String) -> String {
            label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}

enum TaskFlowMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [TaskFlowSchemaV1.self, TaskFlowSchemaV2.self, TaskFlowSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: TaskFlowSchemaV1.self, toVersion: TaskFlowSchemaV2.self),
            .lightweight(fromVersion: TaskFlowSchemaV2.self, toVersion: TaskFlowSchemaV3.self)
        ]
    }
}

typealias TaskItem = TaskFlowSchemaV3.TaskItem
typealias ReminderList = TaskFlowSchemaV3.ReminderList
typealias ReminderTag = TaskFlowSchemaV3.ReminderTag

enum ReminderPriority: String, CaseIterable, Identifiable {
    case none
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "None"
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}

extension TaskItem {
    var isOverdue: Bool {
        guard let referenceDate = dueDate else { return false }
        let todayStart = Calendar.current.startOfDay(for: Date())
        return referenceDate < todayStart
    }

    var daysUntilDue: Int {
        guard let referenceDate = dueDate else { return 0 }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let referenceStart = calendar.startOfDay(for: referenceDate)
        return calendar.dateComponents([.day], from: todayStart, to: referenceStart).day ?? 0
    }

    var safeTitle: String {
        taskTitle ?? "Untitled Task"
    }

    var safeDescription: String {
        taskDescription ?? ""
    }

    var safeDueDate: Date {
        dueDate ?? Date()
    }

    var safeCreatedAt: Date {
        createdAt ?? Date()
    }

    var safeIsFlagged: Bool {
        isFlagged ?? false
    }

    var notes: String {
        get { taskDescription ?? "" }
        set { taskDescription = newValue }
    }

    var reminderURL: String {
        get { urlString ?? "" }
        set { urlString = newValue.nilIfBlank }
    }

    var priority: ReminderPriority {
        get { ReminderPriority(rawValue: priorityRawValue ?? "") ?? .none }
        set { priorityRawValue = newValue.rawValue }
    }

    var listName: String {
        reminderList?.name ?? ReminderDefaults.defaultListName
    }

    var tagLabels: [String] {
        tags
            .map(\.label)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

enum ReminderDefaults {
    static let defaultListName = "Reminders"
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
