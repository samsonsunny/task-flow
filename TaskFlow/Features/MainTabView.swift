import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case today
    case tomorrow
    case upcoming
    case later
}

struct MainTabView: View {
    @State private var showSettings = false
    @State private var selectedTab: AppTab = {
        if ProcessInfo.processInfo.arguments.contains("UITEST_OPEN_UPCOMING") {
            return .upcoming
        }
        return .today
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayTabView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Today", systemImage: "clock.fill")
                }
                .tag(AppTab.today)

            TomorrowView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Tomorrow", systemImage: "clock.arrow.2.circlepath")
                }
                .tag(AppTab.tomorrow)

            UpcomingView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Upcoming", systemImage: "calendar.badge.clock")
                }
                .tag(AppTab.upcoming)

            ListsTabView(onSettings: { showSettings = true })
                .tabItem {
                    Label("Later", systemImage: "tray.full")
                }
                .tag(AppTab.later)
        }
        .sheet(isPresented: $showSettings) {
            MoreView()
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
