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

enum TaskFlowSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

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
        var sortOrder: String?

        init(name: String, createdAt: Date = Date(), reminders: [TaskItem] = [], sortOrder: String? = nil) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
            self.sortOrder = sortOrder
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

enum TaskFlowSchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)

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
        var hasTime: Bool?

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
            sortOrder: String? = nil,
            hasTime: Bool? = nil
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
            self.hasTime = hasTime
        }
    }

    @Model
    final class ReminderList {
        var name: String
        var createdAt: Date
        var reminders: [TaskItem]
        var sortOrder: String?

        init(name: String, createdAt: Date = Date(), reminders: [TaskItem] = [], sortOrder: String? = nil) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
            self.sortOrder = sortOrder
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

enum TaskFlowSchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)

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
        var hasTime: Bool?

        @Relationship(inverse: \TaskItem.subtasks) var parentTask: TaskItem?
        @Relationship var subtasks: [TaskItem]

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
            sortOrder: String? = nil,
            hasTime: Bool? = nil,
            parentTask: TaskItem? = nil
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
            self.hasTime = hasTime
            self.parentTask = parentTask
            self.subtasks = []
        }
    }

    @Model
    final class ReminderList {
        var name: String
        var createdAt: Date
        var reminders: [TaskItem]
        var sortOrder: String?

        init(name: String, createdAt: Date = Date(), reminders: [TaskItem] = [], sortOrder: String? = nil) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
            self.sortOrder = sortOrder
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

enum TaskFlowSchemaV7: VersionedSchema {
    static var versionIdentifier = Schema.Version(7, 0, 0)

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
        var hasTime: Bool?

        @Relationship(inverse: \TaskItem.subtasks) var parentTask: TaskItem?
        @Relationship var subtasks: [TaskItem]

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
            sortOrder: String? = nil,
            hasTime: Bool? = nil,
            parentTask: TaskItem? = nil
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
            self.hasTime = hasTime
            self.parentTask = parentTask
            self.subtasks = []
        }
    }

    @Model
    final class ReminderList {
        var name: String
        var createdAt: Date
        var reminders: [TaskItem]
        var sortOrder: String?

        init(name: String, createdAt: Date = Date(), reminders: [TaskItem] = [], sortOrder: String? = nil) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
            self.sortOrder = sortOrder
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

enum TaskFlowSchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TaskItem.self, ReminderList.self, ReminderTag.self, ReminderListGroup.self]
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
        var hasTime: Bool?

        @Relationship(inverse: \TaskItem.subtasks) var parentTask: TaskItem?
        @Relationship var subtasks: [TaskItem]

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
            sortOrder: String? = nil,
            hasTime: Bool? = nil,
            parentTask: TaskItem? = nil
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
            self.hasTime = hasTime
            self.parentTask = parentTask
            self.subtasks = []
        }
    }

    @Model
    final class ReminderList {
        var name: String
        var createdAt: Date
        var reminders: [TaskItem]
        var sortOrder: String?
        var group: ReminderListGroup?

        init(name: String, createdAt: Date = Date(), reminders: [TaskItem] = [], sortOrder: String? = nil, group: ReminderListGroup? = nil) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
            self.sortOrder = sortOrder
            self.group = group
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

    @Model
    final class ReminderListGroup {
        var name: String
        var sortOrder: String?
        var createdAt: Date
        var lists: [ReminderList]

        init(name: String, sortOrder: String? = nil, createdAt: Date = Date(), lists: [ReminderList] = []) {
            self.name = name
            self.sortOrder = sortOrder
            self.createdAt = createdAt
            self.lists = lists
        }
    }
}

enum TaskFlowMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [TaskFlowSchemaV1.self, TaskFlowSchemaV2.self, TaskFlowSchemaV3.self, TaskFlowSchemaV4.self, TaskFlowSchemaV5.self, TaskFlowSchemaV6.self, TaskFlowSchemaV7.self, TaskFlowSchemaV8.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: TaskFlowSchemaV1.self, toVersion: TaskFlowSchemaV2.self),
            .lightweight(fromVersion: TaskFlowSchemaV2.self, toVersion: TaskFlowSchemaV3.self),
            .lightweight(fromVersion: TaskFlowSchemaV3.self, toVersion: TaskFlowSchemaV4.self),
            .lightweight(fromVersion: TaskFlowSchemaV4.self, toVersion: TaskFlowSchemaV5.self),
            .lightweight(fromVersion: TaskFlowSchemaV5.self, toVersion: TaskFlowSchemaV6.self),
            .lightweight(fromVersion: TaskFlowSchemaV6.self, toVersion: TaskFlowSchemaV7.self),
            .lightweight(fromVersion: TaskFlowSchemaV7.self, toVersion: TaskFlowSchemaV8.self)
        ]
    }
}

typealias TaskItem = TaskFlowSchemaV8.TaskItem

typealias ReminderList = TaskFlowSchemaV8.ReminderList

typealias ReminderTag = TaskFlowSchemaV8.ReminderTag

typealias ReminderListGroup = TaskFlowSchemaV8.ReminderListGroup

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

extension ReminderList {
    @MainActor
    func assignInitialSortOrder(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ReminderList>()
        guard let allLists = try? modelContext.fetch(descriptor) else { return }
        let others = allLists.filter { $0.persistentModelID != persistentModelID }
        let lastOrder = others.compactMap { $0.sortOrder }.sorted().last
        sortOrder = midpoint(between: lastOrder, and: nil)
    }
}

extension ReminderListGroup {
    @MainActor
    func assignInitialSortOrder(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ReminderListGroup>()
        guard let allGroups = try? modelContext.fetch(descriptor) else { return }
        let others = allGroups.filter { $0.persistentModelID != persistentModelID }
        let lastOrder = others.compactMap { $0.sortOrder }.sorted().last
        sortOrder = midpoint(between: lastOrder, and: nil)
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

    var safeHasTime: Bool {
        if let hasTime {
            return hasTime
        }
        guard let dueDate else { return false }
        let components = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
        return components.hour != 0 || components.minute != 0
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

    @MainActor
    func completeDescendants() {
        for subtask in subtasks {
            subtask.isCompleted = true
            subtask.completionDate = Date()
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.completeDescendants()
        }
    }

    @MainActor
    func uncompleteDescendants() {
        for subtask in subtasks {
            subtask.isCompleted = false
            subtask.completionDate = nil
            subtask.uncompleteDescendants()
        }
    }

    @MainActor
    func deleteDescendants() {
        for subtask in subtasks {
            if let taskId = subtask.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            subtask.deleteDescendants()
        }
    }
}

enum ReminderDefaults {
    static let defaultListName = "Inbox"
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

