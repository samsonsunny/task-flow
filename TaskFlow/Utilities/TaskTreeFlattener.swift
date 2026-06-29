import SwiftData
import Foundation

struct FlatTaskNode: Identifiable {
    let id: PersistentIdentifier
    let task: TaskItem
    let depth: Int
    let subtaskCount: Int
}

enum TaskTreeFlattener {
    static func flatten(
        roots: [TaskItem],
        collapsed: Set<PersistentIdentifier>,
        includeCompleted: Bool = false
    ) -> [FlatTaskNode] {
        var result: [FlatTaskNode] = []
        for task in roots {
            flattenNode(task, depth: 0, collapsed: collapsed, includeCompleted: includeCompleted, result: &result)
        }
        return result
    }

    private static func flattenNode(
        _ task: TaskItem,
        depth: Int,
        collapsed: Set<PersistentIdentifier>,
        includeCompleted: Bool,
        result: inout [FlatTaskNode]
    ) {
        let isCollapsed = collapsed.contains(task.persistentModelID)
        let activeSubtasks = includeCompleted
            ? Array(task.subtasks)
            : task.subtasks.filter { !($0.isCompleted == true) }
        let sortedSubtasks = activeSubtasks.sorted { ($0.sortOrder ?? "") < ($1.sortOrder ?? "") }
        result.append(FlatTaskNode(id: task.persistentModelID, task: task, depth: depth, subtaskCount: sortedSubtasks.count))
        if !isCollapsed {
            for subtask in sortedSubtasks {
                flattenNode(subtask, depth: depth + 1, collapsed: collapsed, includeCompleted: includeCompleted, result: &result)
            }
        }
    }
}
