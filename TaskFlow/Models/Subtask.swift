//
//  Subtask.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

import SwiftData
import Foundation

@Model
final class Subtask {
    var subtaskId: String?
    var title: String?
    var completed: Bool?
    var createdAt: Date?

    var task: TaskItem?

    init(
        subtaskId: String? = UUID().uuidString,
        title: String? = "",
        completed: Bool? = false,
        createdAt: Date? = Date()
    ) {
        self.subtaskId = subtaskId
        self.title = title
        self.completed = completed
        self.createdAt = createdAt
    }

    // Safe accessors
    var safeTitle: String {
        title ?? "Untitled Subtask"
    }

    var safeCompleted: Bool {
        completed ?? false
    }

    var safeCreatedAt: Date {
        createdAt ?? Date()
    }
}
