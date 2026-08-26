import SwiftData
import Foundation

struct SubtaskSummary: Equatable {
    let total: Int
    let pending: Int
    let completed: Int

    var isEmpty: Bool { total == 0 }

    static let empty = SubtaskSummary(total: 0, pending: 0, completed: 0)

    var displayText: String {
        "\(completed)/\(total)"
    }
}

extension TaskItem {
    var subtaskSummary: SubtaskSummary {
        let total = subtasks.count
        let completed = subtasks.filter { $0.isCompleted == true }.count
        return SubtaskSummary(total: total, pending: total - completed, completed: completed)
    }
}

struct FlatTaskNode: Identifiable {
    let id: String
    let task: TaskItem
    let depth: Int
    let subtaskSummary: SubtaskSummary
}

enum TaskTreeFlattener {
    static func flatten(
        roots: [TaskItem],
        collapsed: Set<String>,
        includeCompleted: Bool = false,
        nestSubtasks: Bool = true
    ) -> [FlatTaskNode] {
        var result: [FlatTaskNode] = []
        for task in roots {
            if nestSubtasks {
                flattenNode(task, depth: 0, collapsed: collapsed, includeCompleted: includeCompleted, result: &result)
            } else {
                result.append(FlatTaskNode(id: task.taskId ?? "", task: task, depth: 0, subtaskSummary: task.subtaskSummary))
            }
        }
        return result
    }

    private static func flattenNode(
        _ task: TaskItem,
        depth: Int,
        collapsed: Set<String>,
        includeCompleted: Bool,
        result: inout [FlatTaskNode]
    ) {
        let taskId = task.taskId ?? ""
        let isCollapsed = collapsed.contains(taskId)
        let activeSubtasks = includeCompleted
            ? Array(task.subtasks)
            : task.subtasks.filter { !($0.isCompleted == true) }
        let sortedSubtasks = activeSubtasks.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
        result.append(FlatTaskNode(id: taskId, task: task, depth: depth, subtaskSummary: task.subtaskSummary))
        if !isCollapsed {
            for subtask in sortedSubtasks {
                flattenNode(subtask, depth: depth + 1, collapsed: collapsed, includeCompleted: includeCompleted, result: &result)
            }
        }
    }
}
