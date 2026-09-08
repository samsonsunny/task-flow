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

    func commit(text: String, notes: String, target: CaptureTarget, overrideDate: Date? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = TaskItem(
            taskTitle: trimmed,
            dueDate: resolveTargetDate(for: target, overrideDate: overrideDate)
        )
        task.createdAt = Date()
        task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        task.reminderList = resolveTargetList(for: target)
        modelContext.insert(task)
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
    }

    private func resolveTargetList(for target: CaptureTarget) -> ReminderList? {
        if case .list(let listID) = target {
            if let active = try? modelContext.fetch(
                FetchDescriptor<ReminderList>(
                    predicate: #Predicate { $0.persistentModelID == listID }
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
