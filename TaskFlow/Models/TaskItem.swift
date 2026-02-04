//
//  TaskItem.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//
// ==========================================
// MARK: - Updated Models for iCloud Sync
// File: Models/TaskItem.swift
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
        let todayStart = Calendar.current.startOfDay(for: Date())
        return !isCompleted && dueDate < todayStart
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
