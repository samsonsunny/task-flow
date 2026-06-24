import SwiftUI

struct TaskNodeView: View {
    let task: TaskItem
    let depth: Int
    var isCollapsed: Bool
    var showsNesting: Bool
    var onToggleCollapse: () -> Void
    var onToggleCompletion: () -> Void
    var onMoveToToday: (() -> Void)?
    var onMoveToTomorrow: (() -> Void)?
    var onMoveToLater: (() -> Void)?
    var onSchedule: (() -> Void)?
    var onMoveToList: ((ReminderList) -> Void)?
    var availableLists: [ReminderList]
    var onDelete: (() -> Void)?
    var onTap: (() -> Void)?
    var showsDueDate: Bool
    var showsListName: Bool

    var body: some View {
        TaskRowView(
            task: task,
            isCompletedVisualState: task.isCompleted == true,
            onToggleCompletion: onToggleCompletion,
            onMoveToToday: onMoveToToday,
            onMoveToTomorrow: onMoveToTomorrow,
            onMoveToLater: onMoveToLater,
            onSchedule: onSchedule,
            onMoveToList: onMoveToList,
            availableLists: availableLists,
            onDelete: onDelete,
            onTap: onTap,
            showsDueDate: showsDueDate,
            showsListName: showsListName
        )
    }
}
