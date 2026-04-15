import SwiftUI

struct TaskListUpcomingView: View {
    let tasks: [TaskItem]
    let row: (TaskItem) -> AnyView

    var body: some View {
        ForEach(tasks) { task in
            row(task)
        }
    }

    // Section headers removed for MVP simplicity.
}
