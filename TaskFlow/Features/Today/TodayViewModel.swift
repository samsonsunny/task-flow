import SwiftUI
import SwiftData

enum TodayAreaFilter: Hashable {
    case all
    case area(PersistentIdentifier)
}

struct TodayFilterOption: Identifiable {
    let filter: TodayAreaFilter
    let title: String
    let icon: String

    var id: TodayAreaFilter { filter }

    static let all = TodayFilterOption(
        filter: .all,
        title: "All",
        icon: "square.grid.2x2"
    )
}

struct TodaySection: Identifiable {
    let kind: Kind
    let tasks: [TaskItem]

    enum Kind {
        case overdue
        case today
    }

    var id: String {
        switch kind {
        case .overdue: return "overdue"
        case .today: return "today"
        }
    }

    var title: String {
        switch kind {
        case .overdue: return "Overdue"
        case .today: return "Today"
        }
    }

    var iconName: String {
        switch kind {
        case .overdue: return "exclamationmark.circle.fill"
        case .today: return "calendar.circle.fill"
        }
    }

    var tint: Color {
        switch kind {
        case .overdue: return AppTheme.colors.error
        case .today: return AppTheme.colors.primaryAction
        }
    }
}

@MainActor
@Observable
final class TodayViewModel {
    private let modelContext: ModelContext
    private var groups: [ReminderListGroup] = []
    private var allTasks: [TaskItem] = []
    private var now: Date = Date()
    private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    private(set) var sections: [TodaySection] = []
    private(set) var visibleTasks: [TaskItem] = []
    private(set) var filterOptions: [TodayFilterOption] = [.all]
    private(set) var areaFilter: TodayAreaFilter = .all
    private(set) var pendingUndo: CompletionUndo?

    private var undoToken = UUID()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func selectFilter(_ filter: TodayAreaFilter) {
        guard areaFilter != filter else { return }
        areaFilter = filter
        recompute()
    }

    func selectDate(_ date: Date) {
        let newDate = Calendar.current.startOfDay(for: date)
        if newDate == selectedDate {
            recompute()
            return
        }
        selectedDate = newDate
        recompute()
    }

    var isFilteringByArea: Bool {
        areaFilter != .all
    }

    var selectedFilterTitle: String {
        filterOptions.first(where: { $0.filter == areaFilter })?.title ?? "All"
    }

    func update(
        groups: [ReminderListGroup],
        allTasks: [TaskItem],
        now: Date = Date()
    ) {
        self.groups = groups
        self.allTasks = allTasks
        self.now = now
        rebuildFilterOptions()

        let todayStart = Calendar.current.startOfDay(for: now)
        visibleTasks = allTasks
            .filter { matchesAreaFilter($0) }
            .filter { isDueTodayOrOverdue($0, todayStart: todayStart) }
            .sorted { lhs, rhs in
                let lOverdue = isOverdue(lhs, now: now, todayStart: todayStart)
                let rOverdue = isOverdue(rhs, now: now, todayStart: todayStart)
                if lOverdue != rOverdue { return lOverdue && !rOverdue }
                let lhsDate = lhs.dueDate ?? .distantFuture
                let rhsDate = rhs.dueDate ?? .distantFuture
                if lhsDate != rhsDate { return lhsDate < rhsDate }
                let lhsCreated = lhs.createdAt ?? .distantPast
                let rhsCreated = rhs.createdAt ?? .distantPast
                if lhsCreated != rhsCreated { return lhsCreated < rhsCreated }
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }

        sections = visibleTasks.isEmpty ? [] : [TodaySection(kind: .today, tasks: visibleTasks)]
    }

    private func recompute() {
        update(groups: groups, allTasks: allTasks, now: now)
    }

    func isOverdue(_ task: TaskItem) -> Bool {
        let todayStart = Calendar.current.startOfDay(for: now)
        return isOverdue(task, now: now, todayStart: todayStart)
    }

    private func isDueTodayOrOverdue(_ task: TaskItem, todayStart: Date) -> Bool {
        guard !(task.isCompleted ?? false), let dueDate = task.dueDate else { return false }
        let dueStart = Calendar.current.startOfDay(for: dueDate)
        if task.hasTime == true {
            return Calendar.current.isDate(dueDate, inSameDayAs: now) || dueDate < now
        }
        return dueStart == todayStart || dueStart < todayStart
    }

    private func isOverdue(_ task: TaskItem, now: Date, todayStart: Date) -> Bool {
        guard !(task.isCompleted ?? false), let dueDate = task.dueDate else { return false }
        if task.hasTime == true {
            return dueDate < now
        }
        return Calendar.current.startOfDay(for: dueDate) < todayStart
    }

    private func rebuildFilterOptions() {
        let options = [TodayFilterOption.all] + groups.filter { $0.isLocked }.map { group in
            TodayFilterOption(
                filter: .area(group.persistentModelID),
                title: areaDisplayName(group.name),
                icon: icon(for: group)
            )
        }
        filterOptions = options

        if case .area(let id) = areaFilter,
           !groups.contains(where: { $0.persistentModelID == id }) {
            areaFilter = .all
        }
    }

    private func icon(for group: ReminderListGroup) -> String {
        switch group.name {
        case AreaNames.work: return "briefcase"
        case AreaNames.personal: return "house"
        default: return "folder"
        }
    }

    private func matchesAreaFilter(_ task: TaskItem) -> Bool {
        switch areaFilter {
        case .all:
            return true
        case .area(let id):
            return task.reminderList?.group?.persistentModelID == id
        }
    }

    func toggleCompletion(for task: TaskItem) {
        let next = !(task.isCompleted ?? false)
        if next {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            pendingUndo = CompletionUndo(task: task)
            scheduleUndoDismissal()
        } else {
            if pendingUndo?.id == task.persistentModelID {
                pendingUndo = nil
                undoToken = UUID()
            }
            if task.safeHasTime {
                NotificationService.shared.schedule(for: task)
            }
        }
        task.isCompleted = next
        task.completionDate = next ? Date() : nil
        if next, let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
        recompute()
    }

    func undoCompletion() {
        guard let pending = pendingUndo else { return }
        pendingUndo = nil
        undoToken = UUID()

        let task = pending.task
        task.isCompleted = false
        task.completionDate = nil
        if task.safeHasTime {
            NotificationService.shared.schedule(for: task)
        }
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
        recompute()
    }

    private func scheduleUndoDismissal() {
        let token = UUID()
        undoToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, self.undoToken == token else { return }
            self.pendingUndo = nil
            self.recompute()
        }
    }

    // MARK: - Scheduling

    /// Applies a schedule preset without touching any other task property. The context menu
    /// delegates here so date changes follow the same save/notification path as list details.
    func rescheduleTask(_ task: TaskItem, to action: DueDateAction) {
        guard action != .custom else { return }
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        let calendar = Calendar.current
        switch action {
        case .none:
            task.dueDate = nil
        case .today:
            task.dueDate = calendar.startOfDay(for: now)
        case .tomorrow:
            task.dueDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        case .thisWeekend:
            task.dueDate = ReminderSegmentViewModel.nextSaturday(from: now)
        case .nextWeek:
            task.dueDate = ReminderSegmentViewModel.nextMonday(from: now)
        case .custom:
            break
        }
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
        recompute()
    }

    /// Commits the date picked by the "Choose Date…" sheet.
    func scheduleTask(_ task: TaskItem, dueDate: Date?, hasTime: Bool) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        if let date = dueDate {
            if hasTime {
                task.dueDate = date
                task.hasTime = true
                NotificationService.shared.schedule(for: task)
            } else {
                task.dueDate = Calendar.current.startOfDay(for: date)
                task.hasTime = false
            }
        } else {
            task.dueDate = nil
        }
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
        recompute()
    }

    func delete(_ task: TaskItem) {
        if let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        modelContext.delete(task)
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)
        allTasks.removeAll { $0.persistentModelID == task.persistentModelID }
        recompute()
    }
}
