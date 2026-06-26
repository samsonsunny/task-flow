import SwiftUI
import SwiftData

struct FlatTaskNode: Identifiable {
    let id: PersistentIdentifier
    let task: TaskItem
    let depth: Int
    let subtaskCount: Int
}

@MainActor
@Observable
final class ListDetailViewModel {
    private let modelContext: ModelContext
    let listID: ReminderList.ID

    private(set) var list: ReminderList?
    private(set) var tasks: [TaskItem] = []
    private(set) var rootTasks: [TaskItem] = []
    private(set) var flatNodes: [FlatTaskNode] = []

    private(set) var collapsedTasks: Set<PersistentIdentifier> = []
    private(set) var justCompleted: Set<String> = []
    private(set) var now: Date = Date()

    private var allTasks: [TaskItem] = []
    private var allLists: [ReminderList] = []

    init(modelContext: ModelContext, listID: ReminderList.ID) {
        self.modelContext = modelContext
        self.listID = listID
    }

    func update(tasks: [TaskItem], lists: [ReminderList], allTasks: [TaskItem], now: Date = Date()) {
        self.allTasks = allTasks
        self.allLists = lists
        self.now = now
        recompute()
    }

    func toggleCollapse(_ task: TaskItem) {
        if collapsedTasks.contains(task.persistentModelID) {
            collapsedTasks.remove(task.persistentModelID)
        } else {
            collapsedTasks.insert(task.persistentModelID)
        }
        flatNodes = flattenTasks(rootTasks)
    }

    func toggleCompletion(for task: TaskItem) {
        let next = !(task.isCompleted ?? false)
        if next {
            if let id = task.taskId {
                justCompleted.insert(id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self, weak task] in
                    guard let self, let task, task.isCompleted == true else { return }
                    _ = withAnimation {
                        self.justCompleted.remove(id)
                    }
                }
            }
        }
        task.isCompleted = next
        task.completionDate = next ? Date() : nil
        if next, let taskId = task.taskId {
            NotificationService.shared.cancel(taskId: taskId)
        }
        recompute()
    }

    private func recompute() {
        list = allLists.first { $0.persistentModelID == listID }
        tasks = computeTasks()
        rootTasks = tasks.filter { $0.parentTask == nil }
        flatNodes = flattenTasks(rootTasks)
    }

    private func computeTasks() -> [TaskItem] {
        allTasks.filter {
            guard $0.reminderList?.persistentModelID == listID else { return false }
            if $0.isCompleted == true {
                return justCompleted.contains($0.taskId ?? "")
            }
            return true
        }
    }

    private func flattenTasks(_ tasks: [TaskItem]) -> [FlatTaskNode] {
        var result: [FlatTaskNode] = []
        for task in tasks {
            flattenNode(task, depth: 0, result: &result)
        }
        return result
    }

    private func flattenNode(_ task: TaskItem, depth: Int, result: inout [FlatTaskNode]) {
        let isCollapsed = collapsedTasks.contains(task.persistentModelID)
        let activeSubtasks = task.subtasks.filter { !($0.isCompleted == true) }
        result.append(FlatTaskNode(id: task.persistentModelID, task: task, depth: depth, subtaskCount: activeSubtasks.count))
        if !isCollapsed {
            for subtask in activeSubtasks.sorted(by: { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }) {
                flattenNode(subtask, depth: depth + 1, result: &result)
            }
        }
    }
}
