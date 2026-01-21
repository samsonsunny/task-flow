//
//  Task.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//
// ==========================================
// MARK: - Updated Models for iCloud Sync
// File: Models/Task.swift
// ==========================================

import SwiftData
import Foundation

@Model
final class TaskItem {
    var taskId: String?
    var taskTitle: String?
    var taskDescription: String?
    var isCompleted: Bool?
    var completionDate: Date?
    var dueDate: Date?
    var createdAt: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \Subtask.task)
    var subtasks: [Subtask]?
    
    @Relationship(deleteRule: .cascade, inverse: \DailyLogEntry.task)
    var dailyLog: [DailyLogEntry]?
    
    init(
        taskId: String? = UUID().uuidString,
        taskTitle: String? = "",
        taskDescription: String? = "",
        isCompleted: Bool? = false,
        dueDate: Date? = Date(),
        createdAt: Date? = Date()
    ) {
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.subtasks = []
        self.dailyLog = []
    }
    
    // Computed properties with safe unwrapping
    var isOverdue: Bool {
        guard let isCompleted = isCompleted, let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    var daysUntilDue: Int {
        guard let dueDate = dueDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    var completedSubtasksCount: Int {
        guard let subtasks = subtasks else { return 0 }
        return subtasks.filter { $0.completed ?? false }.count
    }
    
    var subtaskProgress: Double {
        guard let subtasks = subtasks, !subtasks.isEmpty else { return 0 }
        return Double(completedSubtasksCount) / Double(subtasks.count)
    }
    
    // Safe accessors for UI
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
    
    var safeIsCompleted: Bool {
        isCompleted ?? false
    }
    
    var safeSubtasks: [Subtask] {
        subtasks ?? []
    }
    
    var safeDailyLog: [DailyLogEntry] {
        dailyLog ?? []
    }
}

// ==========================================
// File: Models/Subtask.swift
// ==========================================

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

// ==========================================
// File: Models/DailyLogEntry.swift
// ==========================================

@Model
final class DailyLogEntry {
    var entryId: String?
    var timestamp: Date?
    var note: String?
    
    var task: TaskItem?
    
    init(
        entryId: String? = UUID().uuidString,
        timestamp: Date? = Date(),
        note: String? = ""
    ) {
        self.entryId = entryId
        self.timestamp = timestamp
        self.note = note
    }
    
    // Safe accessors
    var safeTimestamp: Date {
        timestamp ?? Date()
    }
    
    var safeNote: String {
        note ?? ""
    }
}
