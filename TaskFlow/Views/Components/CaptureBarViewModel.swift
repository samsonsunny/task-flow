import SwiftUI
import SwiftData

enum CaptureTarget: Hashable {
    case segment(HomeSegment)
    case list(ReminderList.ID)
    /// Capture into a specific area's Inbox bucket — the Home target. There is no positional
    /// fallback: a task is never silently filed into a different area than the one selected.
    case area(ReminderListGroup.ID)
}

@MainActor
@Observable
final class CaptureBarViewModel {
    private let modelContext: ModelContext

    private(set) var now: Date = Date()
    var isFocusingCapture = false
    var text = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func refreshNow(now: Date = Date()) {
        self.now = now
    }

    // MARK: - Target Resolution

    func resolveTargetDate(for target: CaptureTarget, overrideDate: Date?) -> Date? {
        if let overrideDate {
            return Calendar.current.startOfDay(for: overrideDate)
        }
        guard case .segment(let segment) = target else { return nil }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        switch segment {
        case .today:
            return todayStart
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: todayStart)
        case .upcoming:
            return ReminderSegmentLogic.upcomingStart(now: now, calendar: calendar)
        }
    }

    // MARK: - Commit

    func commit(
        text: String,
        notes: String,
        target: CaptureTarget,
        selectedAreaID: ReminderListGroup.ID?,
        overrideDate: Date? = nil
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = TaskItem(
            taskTitle: trimmed,
            dueDate: resolveTargetDate(for: target, overrideDate: overrideDate)
        )
        task.createdAt = Date()
        task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task.reminderList = resolveTargetList(for: target, selectedAreaID: selectedAreaID)
        modelContext.insert(task)
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
    }

    /// The list a capture for `target` lands in.
    ///
    /// `.list` is exact. `.area` is the named area's bucket, resolved by pointer.
    /// `.segment` uses the currently selected area's bucket, so a Personal user on Today
    /// never has a task filed into Work.
    func resolveTargetList(
        for target: CaptureTarget,
        selectedAreaID: ReminderListGroup.ID?
    ) -> ReminderList? {
        switch target {
        case .list(let listID):
            return try? modelContext.fetch(
                FetchDescriptor<ReminderList>(
                    predicate: #Predicate { $0.persistentModelID == listID }
                )
            ).first
        case .area(let areaID):
            return resolveAreaBucket(for: areaID, in: modelContext)
        case .segment:
            return resolveAreaBucket(for: selectedAreaID, in: modelContext)
        }
    }
}
