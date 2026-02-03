//
//  DailyLogEntry.swift
//  TaskFlow
//
//  Created by sam on 26-10-2025.
//

import SwiftData
import Foundation

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
