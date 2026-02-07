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
    var remindAt: Date?
    var createdAt: Date?
    

    
    init(
        taskId: String? = UUID().uuidString,
        taskTitle: String? = "",
        taskDescription: String? = "",
        isCompleted: Bool? = false,
        dueDate: Date? = nil,
        remindAt: Date? = nil,
        createdAt: Date? = Date()
    ) {
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.remindAt = remindAt
        self.createdAt = createdAt

    }
    
    // Computed properties with safe unwrapping
    var isOverdue: Bool {
        guard let isCompleted = isCompleted, let referenceDate = reminderReferenceDate else { return false }
        let todayStart = Calendar.current.startOfDay(for: Date())
        return !isCompleted && referenceDate < todayStart
    }
    
    var daysUntilDue: Int {
        guard let referenceDate = reminderReferenceDate else { return 0 }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let referenceStart = calendar.startOfDay(for: referenceDate)
        return calendar.dateComponents([.day], from: todayStart, to: referenceStart).day ?? 0
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

    var reminderReferenceDate: Date? {
        remindAt ?? dueDate
    }
    
    var safeCreatedAt: Date {
        createdAt ?? Date()
    }
    
    var safeIsCompleted: Bool {
        isCompleted ?? false
    }
    

}
