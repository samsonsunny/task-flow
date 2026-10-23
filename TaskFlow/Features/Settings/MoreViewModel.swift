import SwiftUI
import SwiftData

@MainActor
@Observable
final class MoreViewModel {
    private let modelContext: ModelContext

    private(set) var groups: [ReminderListGroup] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func update(groups: [ReminderListGroup]) {
        self.groups = groups
    }

    /// The two permanent domains, Work first. Extra groups are invalid legacy data and are
    /// folded into Work by `AreaReconciler` before the UI reads this list.
    var domains: [ReminderListGroup] {
        let work = groups.first { $0.name == AreaNames.work }
        let personal = groups.first {
            $0.name == AreaNames.personal
                && $0.persistentModelID != work?.persistentModelID
        }
        return [work, personal].compactMap { $0 }
    }
}
