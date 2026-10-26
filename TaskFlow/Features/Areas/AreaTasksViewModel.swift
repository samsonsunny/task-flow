import SwiftUI
import SwiftData

/// The flat task list behind the Work and Personal tabs.
///
/// Unlike `HomeViewModel`, this is not a schedule: every incomplete task filed in the area is
/// shown, dated or not, newest created first. The area is resolved by its canonical name
/// (`AreaNames`) because the locked areas are guaranteed by `AreaReconciler` on every launch.
@MainActor
@Observable
final class AreaTasksViewModel {
    private let modelContext: ModelContext
    let areaName: String

    private var allGroups: [ReminderListGroup] = []
    private var allLists: [ReminderList] = []
    private var allTasks: [TaskItem] = []

    private(set) var area: ReminderListGroup?
    private(set) var tasks: [TaskItem] = []
    private(set) var boardLists: [ReminderList] = []
    private(set) var pendingUndo: CompletionUndo?

    private var showCompleted = false

    private var undoToken = UUID()

    init(modelContext: ModelContext, areaName: String) {
        self.modelContext = modelContext
        self.areaName = areaName
    }

    // MARK: - Update Entry Point

    func update(
        groups: [ReminderListGroup],
        lists: [ReminderList],
        allTasks: [TaskItem]
    ) {
        self.allGroups = groups
        self.allLists = lists
        self.allTasks = allTasks

        guard let area = groups.first(where: { $0.name == areaName }) else {
            self.area = nil
            tasks = []
            boardLists = []
            return
        }
        self.area = area
        boardLists = orderedLists(in: area)

        let areaListIDs = Set(
            lists
                .filter { $0.group?.persistentModelID == area.persistentModelID }
                .map(\.persistentModelID)
        )

        tasks = allTasks
            .filter { task in
                let isPendingUndo = pendingUndo?.id == task.persistentModelID
                guard task.isCompleted != true || isPendingUndo || showCompleted,
                      let listID = task.reminderList?.persistentModelID
                else { return false }
                return areaListIDs.contains(listID)
            }
            .sorted { lhs, rhs in
                let lhsCompleted = lhs.isCompleted ?? false
                let rhsCompleted = rhs.isCompleted ?? false
                if lhsCompleted != rhsCompleted {
                    return !lhsCompleted
                }
                let lhsDate = lhs.createdAt ?? .distantPast
                let rhsDate = rhs.createdAt ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                // Stable tiebreak: seeded fixtures and bulk sync can share a timestamp.
                return (lhs.taskId ?? "") < (rhs.taskId ?? "")
            }
    }

    // MARK: - Board

    func setShowCompleted(_ value: Bool) {
        guard showCompleted != value else { return }
        showCompleted = value
        recompute()
    }

    func tasks(in list: ReminderList) -> [TaskItem] {
        tasks.filter { $0.reminderList?.persistentModelID == list.persistentModelID }
    }

    /// Moves a task to another list in the same area. This is the board's drag action; the
    /// task keeps every other property.
    @discardableResult
    func moveTask(_ task: TaskItem, to list: ReminderList) -> Bool {
        guard boardLists.contains(where: { $0.persistentModelID == list.persistentModelID }),
              task.reminderList?.persistentModelID != list.persistentModelID
        else { return false }

        task.reminderList = list
        try? modelContext.save()
        recompute()
        return true
    }

    private func orderedLists(in area: ReminderListGroup) -> [ReminderList] {
        allLists
            .filter { $0.group?.persistentModelID == area.persistentModelID }
            .sorted { lhs, rhs in
                if lhs.isBucket != rhs.isBucket { return lhs.isBucket }
                return (lhs.sortOrder ?? "", lhs.createdAt) < (rhs.sortOrder ?? "", rhs.createdAt)
            }
    }

    // MARK: - Mutations

    /// Recomputes after a save. `@Model` equality is identity-based, so a property-only change
    /// such as `isCompleted` never triggers the view's `onChange`.
    private func recompute() {
        update(groups: allGroups, lists: allLists, allTasks: allTasks)
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
        // A deleted model remains in the snapshot until the view's `@Query` refreshes, so drop
        // it first or `recompute` puts the row straight back.
        allTasks.removeAll { $0.persistentModelID == task.persistentModelID }
        recompute()
    }
}
