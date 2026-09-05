import SwiftUI
import SwiftData

@MainActor
@Observable
final class CaptureBarViewModel {
    private let modelContext: ModelContext

    private(set) var now: Date = Date()
    var isFocusingCapture = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func refreshNow(now: Date = Date()) {
        self.now = now
    }

    // MARK: - Target Resolution

    func resolveTargetDate(for segment: HomeSegment, overrideDate: Date?) -> Date? {
        if let overrideDate {
            return Calendar.current.startOfDay(for: overrideDate)
        }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        switch segment {
        case .organize:
            return nil
        case .today:
            return todayStart
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: todayStart)
        case .upcoming:
            return ReminderSegmentLogic.upcomingStart(now: now, calendar: calendar)
        }
    }

    // MARK: - Commit

    func commit(text: String, notes: String, for segment: HomeSegment, overrideDate: Date? = nil, activeListID: PersistentIdentifier? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = TaskItem(
            taskTitle: trimmed,
            dueDate: resolveTargetDate(for: segment, overrideDate: overrideDate)
        )
        task.createdAt = Date()
        task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task.reminderList = resolveTargetList(activeListID: activeListID)
        modelContext.insert(task)
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
    }

    private func resolveTargetList(activeListID: PersistentIdentifier? = nil) -> ReminderList? {
        if let activeListID {
            if let active = try? modelContext.fetch(
                FetchDescriptor<ReminderList>(
                    predicate: #Predicate { $0.persistentModelID == activeListID }
                )
            ).first {
                return active
            }
        }
        let defaultName = ReminderDefaults.defaultListName
        let descriptor = FetchDescriptor<ReminderList>(
            predicate: #Predicate { $0.name == defaultName }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let list = ReminderList(name: ReminderDefaults.defaultListName)
        modelContext.insert(list)
        try? modelContext.save()
        return list
    }
}
