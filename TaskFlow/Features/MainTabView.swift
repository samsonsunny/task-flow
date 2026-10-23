import SwiftUI
import SwiftData

/// The app's root navigation surface.
///
/// Exactly four fixed tabs: Today shows what is due now across both domains, Work and
/// Personal show every incomplete task filed in that domain, and More holds domain list
/// management, activity, notifications, and settings. Projects/lists never become tabs.
struct MainTabView: View {
    private enum AppTab: Hashable {
        case today
        case work
        case personal
        case more
    }

    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "text.rectangle.page", value: AppTab.today) {
                TodayTaskListView()
            }

            Tab("Work", systemImage: "briefcase.fill", value: AppTab.work) {
                AreaTasksView(areaName: AreaNames.work, storageKey: AreaNames.work)
            }

            Tab("Personal", systemImage: "person.crop.circle.fill", value: AppTab.personal) {
                AreaTasksView(areaName: AreaNames.personal, storageKey: AreaNames.personal)
            }

            Tab("More", systemImage: "square.grid.2x2.fill", value: AppTab.more) {
                MoreView()
            }
        }
        .tint(AppTheme.colors.tint)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

#Preview("Empty State") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedDefaultAreas(in: container.mainContext)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}

#Preview("With Tasks") {
    let container = TaskPreviewData.container()
    TaskPreviewData.seedBothAreasFixture(into: container)
    return MainTabView()
        .modelContainer(container)
        .environment(AppState())
}
