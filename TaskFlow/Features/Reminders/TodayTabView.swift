import SwiftUI
import SwiftData

struct TodayTabView: View {
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    private var overdueTasks: [TaskItem] {
        ReminderSegmentLogic.filteredTasks(allTasks, for: .overdue, now: Date())
    }

    var body: some View {
        NavigationStack {
            ReminderSegmentDetailView(segment: .today, overdueTasks: overdueTasks)
                .navigationTitle(ReminderSegment.today.title)
                .navigationBarTitleDisplayMode(.large)
        }
    }
}
