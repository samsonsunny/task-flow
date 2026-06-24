import SwiftUI
import SwiftData

struct TodayTabView: View {
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    let onSettings: () -> Void

    private var overdueTasks: [TaskItem] {
        ReminderSegmentLogic.filteredTasks(allTasks, for: .overdue, now: Date())
    }

    var body: some View {
        NavigationStack {
            ReminderSegmentDetailView(segment: .today, overdueTasks: overdueTasks)
                .navigationTitle(ReminderSegment.today.title)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onSettings()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
    }
}
