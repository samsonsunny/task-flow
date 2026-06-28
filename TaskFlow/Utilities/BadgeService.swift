import UIKit
import Foundation
import SwiftData

@MainActor
enum BadgeService {
    private static let lastCountKey = "lastBadgeCount"

    static func update(modelContext: ModelContext) {
        let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        let count = ReminderSegmentLogic.badgeCount(allTasks, now: Date())
        UIApplication.shared.applicationIconBadgeNumber = count
        UserDefaults.standard.set(count, forKey: lastCountKey)
    }

    static var lastCount: Int {
        UserDefaults.standard.integer(forKey: lastCountKey)
    }
}
