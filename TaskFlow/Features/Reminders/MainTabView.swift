import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: ReminderSegment

    init(initialTab: ReminderSegment) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ReminderSegmentDetailView(segment: .today)
            }
            .tabItem {
                Label(ReminderSegment.today.tabTitle, systemImage: ReminderSegment.today.iconName)
            }
            .tag(ReminderSegment.today)

            NavigationStack {
                ReminderSegmentDetailView(segment: .tomorrow)
            }
            .tabItem {
                Label(ReminderSegment.tomorrow.tabTitle, systemImage: ReminderSegment.tomorrow.iconName)
            }
            .tag(ReminderSegment.tomorrow)

            NavigationStack {
                ReminderSegmentDetailView(segment: .upcoming)
            }
            .tabItem {
                Label(ReminderSegment.upcoming.tabTitle, systemImage: ReminderSegment.upcoming.iconName)
            }
            .tag(ReminderSegment.upcoming)
        }
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.ensureDefaultListExists(in: container.mainContext)
    return NavigationStack {
        MainTabView(initialTab: .today)
    }
    .modelContainer(container)
    .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedReminderHomeFixture(into: container)
    return NavigationStack {
        MainTabView(initialTab: .today)
    }
    .modelContainer(container)
    .environment(AppState())
}
