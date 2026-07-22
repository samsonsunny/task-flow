import SwiftUI
import SwiftData

@Observable
final class AppState {
    private(set) var mutationCount: Int = 0

    var collapsedTasks: Set<PersistentIdentifier> = []

    private static let _currentDate: Date = {
        for arg in ProcessInfo.processInfo.arguments {
            let prefix = "UITEST_FIXED_NOW_"
            if arg.hasPrefix(prefix) {
                let dateStr = String(arg.dropFirst(prefix.count))
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy_MM_dd"
                return formatter.date(from: dateStr) ?? Date()
            }
        }
        return Date()
    }()

    let currentDate: Date

    init() {
        self.currentDate = AppState._currentDate
        self.collapsedTasks = Self.loadCollapsedTasks()
    }

    func notifyMutation() {
        mutationCount += 1
    }

    func toggleTaskCollapsed(_ id: PersistentIdentifier) {
        if collapsedTasks.contains(id) {
            collapsedTasks.remove(id)
        } else {
            collapsedTasks.insert(id)
        }
        saveCollapsedTasks()
    }

    private static let collapsedTasksKey = "timeline.collapsedTaskIDs"

    private static func loadCollapsedTasks() -> Set<PersistentIdentifier> {
        guard let keys = UserDefaults.standard.stringArray(forKey: collapsedTasksKey) else {
            return []
        }
        return Set(keys.compactMap { PersistentIdentifier(stableKey: $0) })
    }

    private func saveCollapsedTasks() {
        let keys = collapsedTasks.map(\.stableKey)
        UserDefaults.standard.set(keys, forKey: Self.collapsedTasksKey)
    }
}
