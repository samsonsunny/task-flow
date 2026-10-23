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

    /// Creates a project with its own Inbox bucket. Names are unique case-insensitively so
    /// a user-created project can never shadow the locked Work/Personal areas.
    @discardableResult
    func createProject(named rawName: String) -> ReminderListGroup? {
        guard let name = validatedName(rawName, excluding: nil) else { return nil }

        let project = ReminderListGroup(name: name)
        modelContext.insert(project)
        project.assignInitialSortOrder(in: modelContext)
        makeBucket(for: project, in: modelContext)
        try? modelContext.save()

        groups.append(project)
        return project
    }

    /// Work and Personal are locked: their names are the keys the reconciler relies on.
    func canModify(_ project: ReminderListGroup) -> Bool {
        !project.isLocked
    }

    @discardableResult
    func renameProject(_ project: ReminderListGroup, to rawName: String) -> Bool {
        guard canModify(project),
              let name = validatedName(rawName, excluding: project)
        else { return false }

        project.name = name
        try? modelContext.save()
        return true
    }

    /// Deleting a project deletes its lists and every task inside them.
    @discardableResult
    func deleteProject(_ project: ReminderListGroup) -> Bool {
        guard canModify(project) else { return false }

        let projectLists = project.listsArray
        let projectTasks = projectLists.flatMap { tasksIncludingDescendants(in: $0) }

        for task in projectTasks {
            if let taskId = task.taskId {
                NotificationService.shared.cancel(taskId: taskId)
            }
            modelContext.delete(task)
        }
        for list in projectLists {
            modelContext.delete(list)
        }
        modelContext.delete(project)
        try? modelContext.save()
        BadgeService.update(modelContext: modelContext)

        groups.removeAll { $0.persistentModelID == project.persistentModelID }
        return true
    }

    /// All tasks in a list plus any subtasks reachable from them, deduplicated because a
    /// subtask normally shares its parent's list and can appear in both places.
    private func tasksIncludingDescendants(in list: ReminderList) -> [TaskItem] {
        var tasks: [TaskItem] = []
        var stack = list.remindersArray
        var seen: Set<PersistentIdentifier> = []

        while let task = stack.popLast() {
            guard seen.insert(task.persistentModelID).inserted else { continue }
            tasks.append(task)
            stack.append(contentsOf: task.subtasksArray)
        }
        return tasks
    }

    private func validatedName(
        _ rawName: String,
        excluding project: ReminderListGroup?
    ) -> String? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let reserved = [AreaNames.work, AreaNames.personal, "Home"]
        guard !reserved.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame })
        else { return nil }

        let isTaken = groups.contains { group in
            group.persistentModelID != project?.persistentModelID
                && group.name.caseInsensitiveCompare(name) == .orderedSame
        }
        return isTaken ? nil : name
    }
}
