import SwiftUI
import SwiftData

@Observable
final class AppState {
    private(set) var mutationCount: Int = 0
    var pendingCaptureDate: Date?
    private(set) var hasAutoFocusedOnce = false
    private(set) var pendingCaptureFocus = false

    /// The area currently being browsed and captured into. Session-scoped: never persisted,
    /// so every launch starts on Work. Held here rather than in `HomeView` so the capture bar
    /// on a pushed time screen reads the same value instead of falling back to a default.
    private(set) var selectedAreaID: ReminderListGroup.ID?
    /// Work first, then Personal, so the pills render in a stable order.
    private(set) var areas: [ReminderListGroup] = []

    /// Resolves against the live group objects, so a merge that deleted the previously
    /// selected area falls through to Work instead of retaining a stale identifier.
    var selectedArea: ReminderListGroup? {
        guard let selectedAreaID else { return areas.first }
        return areas.first { $0.persistentModelID == selectedAreaID } ?? areas.first
    }

    func updateAreas(_ groups: [ReminderListGroup]) {
        let ordered = Self.orderAreas(groups)
        let ids = Set(ordered.map(\.persistentModelID))
        areas = ordered
        guard let selectedAreaID, ids.contains(selectedAreaID) else {
            self.selectedAreaID = ordered.first?.persistentModelID
            return
        }
    }

    func selectArea(_ group: ReminderListGroup) {
        guard areas.contains(where: { $0.persistentModelID == group.persistentModelID }) else { return }
        selectedAreaID = group.persistentModelID
    }

    func selectArea(id: ReminderListGroup.ID?) {
        guard let id, areas.contains(where: { $0.persistentModelID == id }) else { return }
        selectedAreaID = id
    }

    private static func orderAreas(_ groups: [ReminderListGroup]) -> [ReminderListGroup] {
        let work = groups.first { $0.name == "Work" }
        let personal = groups.first { $0.name == "Personal" && $0.persistentModelID != work?.persistentModelID }
        var ordered: [ReminderListGroup] = []
        if let work { ordered.append(work) }
        if let personal { ordered.append(personal) }
        for group in groups.sorted(by: { ($0.sortOrder ?? "", $0.createdAt) < ($1.sortOrder ?? "", $1.createdAt) })
        where ordered.allSatisfy({ $0.persistentModelID != group.persistentModelID }) {
            ordered.append(group)
        }
        return ordered
    }

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

    func markAutoFocusedOnce() {
        hasAutoFocusedOnce = true
    }

    func requestCaptureFocus() {
        pendingCaptureFocus = true
    }

    @discardableResult
    func consumeCaptureFocus() -> Bool {
        let wasPending = pendingCaptureFocus
        pendingCaptureFocus = false
        return wasPending
    }
}
