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

            NavigationStack {
                ReminderSegmentDetailView(segment: .tomorrow)
                    .navigationTitle(ReminderSegment.tomorrow.title)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        settingsToolbarItem
                    }
            }
            .tabItem {
                Label("Tomorrow", systemImage: "sunrise.fill")
            }

            NavigationStack {
                ReminderSegmentDetailView(segment: .upcoming)
                    .navigationTitle(ReminderSegment.upcoming.title)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        settingsToolbarItem
                    }
            }
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

    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
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
