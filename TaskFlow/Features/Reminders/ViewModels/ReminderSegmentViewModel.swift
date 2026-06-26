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
        self.filteredTasks = ReminderSegmentLogic.filteredTasks(tasks, for: segment, now: now)
        self.groupedSections = ReminderSegmentLogic.datedSections(from: tasks, for: segment, now: now)
        self.upcomingGroups = ReminderSegmentLogic.upcomingGroups(from: tasks, now: now)
        let sorted = ReminderSegmentLogic.sortedTasks(self.filteredTasks, for: segment)
        let recent = tasks.filter { justCompleted.contains($0.taskId ?? "") }
        self.sortedFlatTasks = sorted + recent
    }
}
