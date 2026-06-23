import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayTabView()
                .tabItem {
                    Label("Today", systemImage: "calendar.circle.fill")
                }

            NavigationStack {
                ReminderSegmentDetailView(segment: .tomorrow)
                    .navigationTitle(ReminderSegment.tomorrow.title)
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Tomorrow", systemImage: "sunrise.fill")
            }

            NavigationStack {
                ReminderSegmentDetailView(segment: .upcoming)
                    .navigationTitle(ReminderSegment.upcoming.title)
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Upcoming", systemImage: "calendar.badge.clock")
            }

            ListsTabView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
        }
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}
