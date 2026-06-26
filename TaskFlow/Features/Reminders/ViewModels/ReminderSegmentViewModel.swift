import SwiftUI
import SwiftData

@MainActor
@Observable
final class ReminderSegmentViewModel {
    private let modelContext: ModelContext
    let segment: ReminderSegment
    let overdueTasks: [TaskItem]

    private(set) var now: Date = Date()
    private(set) var showOverdue: Bool = true
    private(set) var justCompleted: Set<String> = []

    private(set) var filteredTasks: [TaskItem] = []
    private(set) var groupedSections: [TaskUIModel.DatedSection] = []
    private(set) var upcomingGroups: [TaskUIModel.UpcomingGroup] = []
    private(set) var sortedFlatTasks: [TaskItem] = []

    private var lists: [ReminderList] = []

    init(modelContext: ModelContext, segment: ReminderSegment, overdueTasks: [TaskItem] = []) {
        self.modelContext = modelContext
        self.segment = segment
        self.overdueTasks = overdueTasks
    }

    func refreshNow() {
        now = Date()
    }

    func update(tasks: [TaskItem], lists: [ReminderList], now: Date = Date()) {
        self.now = now
        self.lists = lists
        self.filteredTasks = ReminderSegmentLogic.filteredTasks(tasks, for: segment, now: now)
        self.groupedSections = ReminderSegmentLogic.datedSections(from: tasks, for: segment, now: now)
        self.upcomingGroups = ReminderSegmentLogic.upcomingGroups(from: tasks, now: now)
        let sorted = ReminderSegmentLogic.sortedTasks(self.filteredTasks, for: segment)
        let recent = tasks.filter { justCompleted.contains($0.taskId ?? "") }
        self.sortedFlatTasks = sorted + recent
    }

    var contextualDate: Date? {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        switch segment {
        case .today: return todayStart
        case .tomorrow: return calendar.date(byAdding: .day, value: 1, to: todayStart)
        default: return nil
        }
    }

    func captureDateHint(activeCaptureDate: Date?) -> String? {
        let date: Date?
        if segment == .upcoming {
            date = activeCaptureDate
        } else {
            date = contextualDate
        }
        guard let date else { return nil }
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        return TaskUIModel.compactDayTitle(for: date)
    }

    func resolvedQuickCaptureList() -> ReminderList {
        let defaultName = ReminderDefaults.defaultListName
        let descriptor = FetchDescriptor<ReminderList>(
            predicate: #Predicate { $0.name == defaultName }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let list = ReminderList(name: ReminderDefaults.defaultListName)
        modelContext.insert(list)
        return list
    }

    func shouldShowDueDate(for segment: ReminderSegment) -> Bool {
        switch segment {
        case .today, .tomorrow, .later: return false
        case .upcoming, .overdue: return true
        }
    }

    var otherLists: [ReminderList] {
        lists
    }
}
