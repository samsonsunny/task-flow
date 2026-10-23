import SwiftUI
import SwiftData

@Observable
final class AppState {
    private(set) var mutationCount: Int = 0
    var pendingCaptureDate: Date?
    private(set) var hasAutoFocusedOnce = false
    private(set) var pendingCaptureFocus = false

    /// The domain currently being browsed and captured into. Session-scoped: never persisted,
    /// so every launch starts on Work. Only Work and Personal are exposed; extra groups are
    /// invalid legacy data and must not become a third selectable area.
    private(set) var selectedAreaID: ReminderListGroup.ID?
    /// Work first, then Personal.
    private(set) var areas: [ReminderListGroup] = []

    /// Resolves against the live group objects, so a merge that deleted the previously
    /// selected area falls through to Work instead of retaining a stale identifier.
    var selectedArea: ReminderListGroup? {
        guard let selectedAreaID else { return areas.first }
        return areas.first { $0.persistentModelID == selectedAreaID } ?? areas.first
    }

    func updateAreas(_ groups: [ReminderListGroup]) {
        let ordered = Self.orderAreas(groups.filter { $0.isLocked })
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
        return [work, personal].compactMap { $0 }
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
