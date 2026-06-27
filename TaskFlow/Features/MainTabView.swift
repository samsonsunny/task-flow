import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var showSettings = false

    var body: some View {
        TabView {
            TodayTabView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Today", systemImage: "calendar.circle.fill")
                }

            TomorrowView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Tomorrow", systemImage: "sunrise.fill")
                }

            UpcomingView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Upcoming", systemImage: "calendar.badge.clock")
                }

            ListsTabView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
