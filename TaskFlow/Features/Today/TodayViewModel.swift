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
        let calendar = Calendar.current
        let newDate = calendar.startOfDay(for: date)
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
        if Calendar.current.startOfDay(for: selectedDate) > Calendar.current.startOfDay(for: now).addingTimeInterval(86400 * 365) {
            // keep as is
        }
        rebuildFilterOptions()

        let calendar = Calendar.current
        let referenceStart = Calendar.current.startOfDay(for: selectedDate)
        let nowStart = calendar.startOfDay(for: now)
        var overdue: [TaskItem] = []
        var dueOnSelected: [TaskItem] = []

        for task in allTasks {
            let isPendingUndo = pendingUndo?.id == task.persistentModelID
            guard task.isCompleted != true || isPendingUndo else { continue }
            guard matchesAreaFilter(task) else { continue }
            guard let dueDate = task.dueDate else { continue }
            let dueStart = calendar.startOfDay(for: dueDate)
            // Overdue relative to selected date start
            if dueStart < referenceStart {
                overdue.append(task)
                continue
            }
            if dueStart == referenceStart {
                dueOnSelected.append(task)
            }
        }

        func sort(_ tasks: [TaskItem]) -> [TaskItem] {
            tasks.sorted { lhs, rhs in
                let lhsDate = lhs.dueDate ?? .distantFuture
                let rhsDate = rhs.dueDate ?? .distantFuture
                if lhsDate != rhsDate { return lhsDate < rhsDate }
                let lhsCreated = lhs.createdAt ?? .distantPast
                let rhsCreated = rhs.createdAt ?? .distantPast
                if lhsCreated != rhsCreated { return lhsCreated < rhsCreated }
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }
        }

        var result: [TodaySection] = []
        if !overdue.isEmpty {
            result.append(TodaySection(kind: .overdue, tasks: sort(overdue)))
        }
        if !dueOnSelected.isEmpty {
            result.append(TodaySection(kind: .today, tasks: sort(dueOnSelected)))
        }
        sections = result
    }

    private func recompute() {
        update(groups: groups, allTasks: allTasks, now: now)
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
