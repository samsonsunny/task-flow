import SwiftUI
import SwiftData

/// The app's root navigation surface.
///
/// Fixed tabs: Today shows what is due now, Work and Home show every incomplete task filed
/// in that area, and More holds organization, activity, notifications, and settings.
/// User-created projects fill the remaining slots up to the platform cap (5 tabs in compact
/// width, including iPhone and iPad Split View; 6 in regular width); any further projects
/// stay reachable from the Projects list in More.
struct MainTabView: View {
    private static let fixedTabCount = 4
    private static let compactTabLimit = 5
    private static let regularTabLimit = 6

    private enum AppTab: Hashable {
        case today
        case work
        case home
        case more
        case project(PersistentIdentifier)
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query(sort: \ReminderListGroup.sortOrder, order: .forward) private var groups: [ReminderListGroup]

    @State private var selectedTab: AppTab = .today

    private var projects: [ReminderListGroup] {
        groups.filter { !$0.isLocked }
    }

    private var visibleProjects: [ReminderListGroup] {
        Array(projects.prefix(max(0, visibleTabLimit - Self.fixedTabCount)))
    }

    private var visibleTabLimit: Int {
        horizontalSizeClass == .compact ? Self.compactTabLimit : Self.regularTabLimit
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "text.rectangle.page", value: AppTab.today) {
                TodayTaskListView()
            }

            Tab("Work", systemImage: "briefcase.fill", value: AppTab.work) {
                AreaTasksView(areaName: AreaNames.work, storageKey: AreaNames.work)
            }

            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                AreaTasksView(areaName: AreaNames.personal, storageKey: AreaNames.personal)
            }

            ForEach(visibleProjects) { project in
                Tab(
                    areaDisplayName(project.name),
                    systemImage: "folder.fill",
                    value: AppTab.project(project.persistentModelID)
                ) {
                    AreaTasksView(
                        areaName: project.name,
                        storageKey: project.persistentModelID.stableKey
                    )
                }
            }

            Tab("More", systemImage: "square.grid.2x2.fill", value: AppTab.more) {
                MoreView()
            }
        }
        .tint(AppTheme.colors.tint)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .onChange(of: groups) { _, _ in
            resetSelectionIfHidden()
        }
        .onChange(of: visibleTabLimit) { _, _ in
            resetSelectionIfHidden()
        }
    }

    private func resetSelectionIfHidden() {
        if case .project(let id) = selectedTab,
           !visibleProjects.contains(where: { $0.persistentModelID == id }) {
            selectedTab = .today
        }
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
