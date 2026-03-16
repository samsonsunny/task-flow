import SwiftUI

enum TaskBucket: String, CaseIterable, Identifiable {
    case today
    case tomorrow
    case upcoming = "later"
    case someday

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .upcoming: return "Upcoming"
        case .someday: return "Someday"
        }
    }

    var iconName: String {
        switch self {
        case .today: return "sun.max"
        case .tomorrow: return "calendar"
        case .upcoming: return "tray.full"
        case .someday: return "archivebox"
        }
    }
}

enum TaskListCaptureMetrics {
    static let bottomInset: CGFloat = 10
    static let horizontalScreenInset: CGFloat = 16
    static let inputMinHeight: CGFloat = 54
    static let inputVerticalPadding: CGFloat = 4
    static let inputHorizontalPadding: CGFloat = 12
    static let cornerRadius: CGFloat = 20
    static let containerVerticalPadding: CGFloat = 8
}

// Upcoming is a single flat list for MVP simplicity.

enum SidebarDestination: Hashable, Identifiable {
    case bucket(TaskBucket)

    var id: String {
        switch self {
        case .bucket(let bucket): return bucket.rawValue
        }
    }
}

enum CaptureDueSelection: Hashable {
    case today
    case tomorrow
    case someday
    case chooseDay(Date)
}
