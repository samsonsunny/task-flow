//
//  TaskItem.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

import Foundation
import SwiftData

enum TaskFlowSchemaV10: VersionedSchema {
    static var versionIdentifier = Schema.Version(10, 0, 0)

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
        @Relationship var tags: [ReminderTag]?

        var sortOrder: Int?
        var hasTime: Bool?
        var deferCount: Int?

        @Relationship(inverse: \TaskItem.subtasks) var parentTask: TaskItem?
        @Relationship var subtasks: [TaskItem]?

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
            sortOrder: Int? = nil,
            hasTime: Bool? = nil,
            deferCount: Int? = nil,
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
            self.deferCount = deferCount
            self.parentTask = parentTask
            self.subtasks = []
        }

        var tagsArray: [ReminderTag] { tags ?? [] }

        var subtasksArray: [TaskItem] { subtasks ?? [] }
    }

    @Model
    final class ReminderList {
        var name: String = ""
        var createdAt: Date = Date()
        var reminders: [TaskItem]?
        var sortOrder: String?
        @Relationship(inverse: \ReminderListGroup.lists) var group: ReminderListGroup?

        init(name: String = "", createdAt: Date = Date(), reminders: [TaskItem] = [], sortOrder: String? = nil, group: ReminderListGroup? = nil) {
            self.name = name
            self.createdAt = createdAt
            self.reminders = reminders
            self.sortOrder = sortOrder
            self.group = group
        }

        var remindersArray: [TaskItem] { reminders ?? [] }

        /// The area's Inbox bucket — derived, never persisted.
        ///
        /// A bucket is the owning area's list named "Inbox". This is a computed property
        /// rather than a stored pointer because the CloudKit production schema for this
        /// record is already sealed: adding `defaultForGroup` to it makes every mirroring
        /// export abort with "Cannot create or modify field in production schema",
        /// silently stranding local changes off-device.
        ///
        /// Work and Personal keep a name-based bucket. A user-created project may rename
        /// its bucket, in which case the oldest list inherits the role (see
        /// `ReminderListGroup.inboxBucket`).
        var isBucket: Bool {
            guard let group else { return false }
            return group.inboxBucket?.persistentModelID == persistentModelID
        }
    }

    @Model
    final class ReminderTag {
        var label: String = ""
        var normalizedLabel: String = ""
        @Relationship(inverse: \TaskItem.tags) var tasks: [TaskItem]?

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
        var name: String = ""
        var sortOrder: String?
        var createdAt: Date = Date()
        var lists: [ReminderList]?

        init(name: String = "", sortOrder: String? = nil, createdAt: Date = Date(), lists: [ReminderList] = []) {
            self.name = name
            self.sortOrder = sortOrder
            self.createdAt = createdAt
            self.lists = lists
        }

        var listsArray: [ReminderList] { lists ?? [] }

        /// Whether this area is one of the two locked areas — derived, never persisted.
        var isLocked: Bool {
            name == "Work" || name == "Personal"
        }

        /// The area's Inbox bucket — derived, never persisted.
        var inboxBucket: ReminderList? {
            if let named = listsArray.first(where: { $0.name == "Inbox" }) {
                return named
            }
            guard !isLocked else { return nil }
            return listsArray.min {
                ($0.createdAt, $0.name) < ($1.createdAt, $1.name)
            }
        }
    }
}

typealias TaskItem = TaskFlowSchemaV10.TaskItem

typealias ReminderList = TaskFlowSchemaV10.ReminderList

typealias ReminderTag = TaskFlowSchemaV10.ReminderTag

typealias ReminderListGroup = TaskFlowSchemaV10.ReminderListGroup

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
        let lastOrder = others.compactMap { $0.sortOrder }.compactMap(Int.init).max() ?? others.count
        sortOrder = String(lastOrder + 1)
    }
}

extension ReminderListGroup {
    @MainActor
    func assignInitialSortOrder(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ReminderListGroup>()
        guard let allGroups = try? modelContext.fetch(descriptor) else { return }
        let others = allGroups.filter { $0.persistentModelID != persistentModelID }
        let lastOrder = others.compactMap { $0.sortOrder }.compactMap(Int.init).max() ?? others.count
        sortOrder = String(lastOrder + 1)
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
        reminderList?.name ?? ""
    }

    var tagLabels: [String] {
        tagsArray
            .map(\.label)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    @MainActor
    func completeDescendants() {
        for subtask in subtasksArray {
            subtask.isCompleted = true
            subtask.completionDate = Date()
            subtask.completeDescendants()
        }
    }

    @MainActor
    func uncompleteDescendants() {
        for subtask in subtasksArray {
            subtask.isCompleted = false
            subtask.completionDate = nil
            subtask.uncompleteDescendants()
        }
    }

    @MainActor
    func deleteDescendants() {
        for subtask in subtasksArray {
            subtask.deleteDescendants()
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

