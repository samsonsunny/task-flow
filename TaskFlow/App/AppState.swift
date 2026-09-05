import SwiftUI
import SwiftData

@Observable
final class AppState {
    private(set) var mutationCount: Int = 0
    var activeListID: PersistentIdentifier?
    var pendingCaptureDate: Date?

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
    }

    func notifyMutation() {
        mutationCount += 1
    }
}
